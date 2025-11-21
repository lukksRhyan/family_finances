import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';

import 'expense.dart';
import 'receipt.dart';
import 'product.dart';
import 'product_category.dart';
import 'expense_category.dart';
import 'nfce.dart';
// import 'partnership.dart'; // Não está sendo usado diretamente aqui, mas ok manter se precisar

class FinanceState with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  late GeminiService _geminiService;

  StreamSubscription<List<Expense>>? _expensesPrivateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSharedSub;

  StreamSubscription<List<Receipt>>? _receiptsPrivateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _receiptsSharedSub;

  StreamSubscription<List<Product>>? _productsPrivateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSharedSub;

  StreamSubscription<List<ProductCategory>>? _categoriesPrivateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categoriesSharedSub;
  
  StreamSubscription<DocumentSnapshot>? _partnershipSnapSub;

  String? _uid;
  bool _isLoading = true;

  String? _activePartnershipId;
  String? _activeSharedCollectionId;

  String get currentPartnerId => _activePartnershipId ?? '';

  String? _userName;
  String? _partnerName;
  
  // Getters
  String? get userName => _userName;
  String? get partnerName => _partnerName;

  List<Expense> _expensesPrivate = [];
  List<Expense> _expensesShared = [];

  List<Receipt> _receiptsPrivate = [];
  List<Receipt> _receiptsShared = [];

  List<Product> _productsPrivate = [];
  List<Product> _productsShared = [];

  List<ProductCategory> _categoriesPrivate = [];
  List<ProductCategory> _categoriesShared = [];

  final List<ExpenseCategory> _expenseCategories = [
    ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart),
    ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    ExpenseCategory(name: 'Moradia', icon: Icons.home),
    ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
    ExpenseCategory(name: 'Outros', icon: Icons.category),
  ];

  FinanceState() {
    _geminiService = GeminiService();
    FirebaseAuth.instance.authStateChanges().listen(_handleAuth);
    // Tenta carregar usuário atual se já existir
    if (FirebaseAuth.instance.currentUser != null) {
       _handleAuth(FirebaseAuth.instance.currentUser);
    }
  }

  bool get isLoggedIn => _uid != null;
  bool get hasPartnership => _activeSharedCollectionId != null;

  bool get isLoading => _isLoading;

  List<Expense> get expenses {
    final merged = [..._expensesPrivate, ..._expensesShared];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  List<Receipt> get receipts {
    final merged = [..._receiptsPrivate, ..._receiptsShared];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  List<Product> get shoppingListProducts {
    final merged = [..._productsPrivate, ..._productsShared];
    merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return merged;
  }

  List<ProductCategory> get productCategories {
    final merged = [
      ProductCategory.indefinida,
      ..._categoriesPrivate,
      ..._categoriesShared
    ];
    return merged;
  }

  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  void _handleAuth(User? user) {
    if (user != null && _uid != user.uid) {
      _uid = user.uid;
      _initializeCloud(user.uid);
    } else if (user == null) {
      _uid = null;
      _clearCloud();
      _initializeLocal();
    }
  }

  Future<void> _clearCloud() async {
    await _expensesPrivateSub?.cancel();
    await _expensesSharedSub?.cancel();
    await _receiptsPrivateSub?.cancel();
    await _receiptsSharedSub?.cancel();
    await _productsPrivateSub?.cancel();
    await _productsSharedSub?.cancel();
    await _categoriesPrivateSub?.cancel();
    await _categoriesSharedSub?.cancel();
    await _partnershipSnapSub?.cancel();

    _expensesPrivateSub = null;
    _expensesSharedSub = null;
    _receiptsPrivateSub = null;
    _receiptsSharedSub = null;
    _productsPrivateSub = null;
    _productsSharedSub = null;
    _categoriesPrivateSub = null;
    _categoriesSharedSub = null;
    _partnershipSnapSub = null;

    _activePartnershipId = null;
    _activeSharedCollectionId = null;
    _partnerName = null;
    _userName = null;
  }

  Future<void> _initializeLocal() async {
    _isLoading = true;
    notifyListeners();

    _expensesPrivate = await _databaseHelper.getAllExpenses();
    _receiptsPrivate = await _databaseHelper.getAllReceipts();
    _categoriesPrivate = await _databaseHelper.getAllProductCategories();
    _productsPrivate = await _databaseHelper.getAllProducts();

    _expensesShared = [];
    _receiptsShared = [];
    _productsShared = [];
    _categoriesShared = [];

    _isLoading = false;
    notifyListeners();
  }

  void _initializeCloud(String uid) {
    _isLoading = true;
    notifyListeners();

    _firestoreService = FirestoreService(uid: uid);

    // 1. Carrega o nome do usuário atual
    _firestoreService!.getUserName(uid).then((name) {
      _userName = name;
      notifyListeners();
    });

    // Cancela assinatura anterior se houver para evitar duplicidade
    _partnershipSnapSub?.cancel();
    
    _partnershipSnapSub = FirebaseFirestore.instance
        .collection('partnerships')
        .doc(uid)
        .snapshots()
        .listen(_handlePartnershipSnapshot, onError: (e) {
          print("Erro no listener de parceria: $e");
        });

    _subscribePrivateCollections();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoading = false;
      notifyListeners();
    });
  }

  void _handlePartnershipSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) {
      // Se o documento foi deletado ou não existe, limpa tudo
      if (_activeSharedCollectionId != null) {
        _activePartnershipId = null;
        _activeSharedCollectionId = null;
        _partnerName = null;
        _unsubscribeSharedCollections();
        _clearShared();
        notifyListeners();
      }
      return;
    }

    final data = snap.data() as Map<String, dynamic>;
    final sharedId = data['sharedCollectionId'];
    final partnerId = data['partnerId']; 
    final pid = snap.id; // Meu ID (doc id)

    // Se mudou o ID compartilhado ou ainda não tínhamos um
    if (_activeSharedCollectionId != sharedId) {
      _activePartnershipId = pid;
      _activeSharedCollectionId = sharedId;

      // Busca o nome do parceiro
      if (partnerId != null && _firestoreService != null) {
        _firestoreService!.getUserName(partnerId).then((name) {
          _partnerName = name;
          notifyListeners();
        });
      }

      _subscribeSharedCollections();
      notifyListeners();
    }
  }

  void _subscribePrivateCollections() {
    _expensesPrivateSub = _firestoreService!.getExpensesStream().listen((d) {
      _expensesPrivate = d;
      notifyListeners();
    });

    _receiptsPrivateSub = _firestoreService!.getReceiptsStream().listen((d) {
      _receiptsPrivate = d;
      notifyListeners();
    });

    _productsPrivateSub = _firestoreService!.getProductsStream().listen((d) {
      _productsPrivate = d;
      notifyListeners();
    });

    _categoriesPrivateSub =
        _firestoreService!.getCategoriesStream().listen((d) {
      _categoriesPrivate = d;
      notifyListeners();
    });
  }

  void _subscribeSharedCollections() {
    if (_activeSharedCollectionId == null || _activePartnershipId == null) return;

    // IMPORTANTE: O caminho deve usar o sharedCollectionId ou a estrutura que definimos na SettingsScreen.
    // Na SettingsScreen definimos: partnerships/{myUid} -> field: sharedCollectionId
    // Mas onde guardamos os dados? 
    // Na regra de segurança definimos: match /partnerships/{partnershipId}/shared/{document=**}
    // Onde {partnershipId} deve ser o ID do documento onde vamos escrever.
    // O seu código original usava doc(_activePartnershipId).collection('shared').
    // Como _activePartnershipId no _handlePartnershipSnapshot é 'pid' (que é o MEU uid),
    // cada usuário vai escrever no SEU PRÓPRIO documento partnerships/{meuID}/shared?
    // NÃO. Isso separaria os dados.
    //
    // CORREÇÃO LÓGICA DE DADOS COMPARTILHADOS:
    // Normalmente, dados compartilhados ficam em uma coleção separada ou em UM dos documentos.
    // Para simplificar e manter seu código atual:
    // Vamos assumir que ambos escrevem no documento cujo ID é 'sharedCollectionId' 
    // OU (mais fácil com suas regras atuais): Ambos escrevem no documento de quem criou a parceria?
    //
    // Vamos manter a lógica simples: Os dados ficam duplicados ou centralizados?
    // Pelo código anterior: collection('partnerships').doc(_activePartnershipId).collection('shared')
    // Isso significa que os dados ficam no MEU documento. O parceiro não veria.
    //
    // CORREÇÃO DEFINITIVA: Vamos usar o 'sharedCollectionId' como o ID do documento na coleção 'shared_data' (nova root)
    // OU, para não quebrar suas regras atuais, vamos usar o campo 'sharedCollectionId' como o ID do DOC na coleção partnerships?
    // 
    // Vamos adotar a estratégia do código SettingsScreen: 
    // sharedCollectionId = "${ids[0]}_${ids[1]}_shared";
    // Vamos usar esse ID para guardar os dados!
    
    final base = FirebaseFirestore.instance
        .collection('partnerships')
        .doc(_activeSharedCollectionId) // <--- MUDANÇA: Usamos o ID Comum, não o meu ID
        .collection('shared');

    _expensesSharedSub = base
        .doc('expenses')
        .collection('items')
        .snapshots()
        .listen((snap) {
      _expensesShared = snap.docs
          .map((doc) =>
              Expense.fromMapFromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });

    _receiptsSharedSub = base
        .doc('receipts')
        .collection('items')
        .snapshots()
        .listen((snap) {
      _receiptsShared = snap.docs
          .map((doc) =>
              Receipt.fromMapFromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });

    _productsSharedSub = base
        .doc('products')
        .collection('items')
        .snapshots()
        .listen((snap) {
      _productsShared = snap.docs
          .map((doc) =>
              Product.fromMapFromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });

    _categoriesSharedSub = base
        .doc('productCategories')
        .collection('items')
        .snapshots()
        .listen((snap) {
      _categoriesShared = snap.docs
          .map((doc) => ProductCategory.fromMapFromFirestore(
              doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  void _unsubscribeSharedCollections() async {
    await _expensesSharedSub?.cancel();
    await _receiptsSharedSub?.cancel();
    await _productsSharedSub?.cancel();
    await _categoriesSharedSub?.cancel();

    _expensesSharedSub = null;
    _receiptsSharedSub = null;
    _productsSharedSub = null;
    _categoriesSharedSub = null;
  }

  void _clearShared() {
    _expensesShared = [];
    _receiptsShared = [];
    _productsShared = [];
    _categoriesShared = [];
  }

  // ==========================================================================
  // CRUD METHODS (Com proteção contra NOT_FOUND)
  // ==========================================================================

  Future<void> addExpense(Expense e) async {
    // Itens novos vão para o compartilhado se houver parceria
    if (hasPartnership) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId) // Usar ID comum
          .collection('shared')
          .doc('expenses')
          .collection('items');
      await base.add(e.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addExpense(e);
    } else {
      final newE = await _databaseHelper.createExpense(e);
      _expensesPrivate.insert(0, newE.copyWith(localId: newE.localId));
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense e) async {
    // VERIFICAÇÃO CRÍTICA: Onde está esse item?
    final bool existsInShared = _expensesShared.any((item) => item.id == e.id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('expenses')
          .collection('items');
      await base.doc(e.id).update(e.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      // Se não está no compartilhado, tenta atualizar no privado
      await _firestoreService!.updateExpense(e);
    } else {
      await _databaseHelper.updateExpense(e);
      _expensesPrivate = await _databaseHelper.getAllExpenses();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    final bool existsInShared = _expensesShared.any((item) => item.id == id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('expenses')
          .collection('items');
      await base.doc(id).delete();
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteExpense(id);
    } else {
      final lid = int.tryParse(id);
      if (lid == null) return;
      await _databaseHelper.deleteExpense(lid);
      _expensesPrivate.removeWhere((e) => e.localId == lid);
      notifyListeners();
    }
  }

  Future<void> addReceipt(Receipt r) async {
    if (hasPartnership) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('receipts')
          .collection('items');
      await base.add(r.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addReceipt(r);
    } else {
      final newR = await _databaseHelper.createReceipt(r);
      _receiptsPrivate.insert(0, newR.copyWith(localId: newR.localId));
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt r) async {
    // VERIFICAÇÃO CRÍTICA
    final bool existsInShared = _receiptsShared.any((item) => item.id == r.id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('receipts')
          .collection('items');
      await base.doc(r.id).update(r.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateReceipt(r);
    } else {
      await _databaseHelper.updateReceipt(r);
      _receiptsPrivate = await _databaseHelper.getAllReceipts();
      notifyListeners();
    }
  }

  Future<void> deleteReceipt(String id) async {
    final bool existsInShared = _receiptsShared.any((item) => item.id == id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('receipts')
          .collection('items');
      await base.doc(id).delete();
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteReceipt(id);
    } else {
      final lid = int.tryParse(id);
      if (lid == null) return;
      await _databaseHelper.deleteReceipt(lid);
      _receiptsPrivate.removeWhere((e) => e.localId == lid);
      notifyListeners();
    }
  }

  Future<void> addProduct(Product p) async {
    if (hasPartnership) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('products').collection('items');
      await base.add(p.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProduct(p);
    } else {
      final newP = await _databaseHelper.createProduct(p);
      _productsPrivate.add(newP.copyWith(localId: newP.localId));
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product p) async {
    final bool existsInShared = _productsShared.any((item) => item.id == p.id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('products')
          .collection('items');
      await base.doc(p.id).update(p.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateProduct(p);
    } else {
      await _databaseHelper.updateProduct(p);
      _productsPrivate = await _databaseHelper.getAllProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final bool existsInShared = _productsShared.any((item) => item.id == id);

    if (hasPartnership && existsInShared) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('products')
          .collection('items');
      await base.doc(id).delete();
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteProduct(id);
    } else {
      final lid = int.tryParse(id);
      if (lid == null) return;
      await _databaseHelper.deleteProduct(lid);
      _productsPrivate.removeWhere((p) => p.localId == lid);
      notifyListeners();
    }
  }

  Future<void> toggleProductChecked(Product p, bool val) async {
    final updated = p.copyWith(isChecked: val);
    // Reutiliza a lógica segura do updateProduct
    await updateProduct(updated);
  }

  Future<void> addProductCategory(ProductCategory c) async {
    if (hasPartnership) {
      final base = FirebaseFirestore.instance
          .collection('partnerships')
          .doc(_activeSharedCollectionId)
          .collection('shared')
          .doc('productCategories')
          .collection('items');
      await base.add(c.toMapForFirestore());
    } else if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProductCategory(c);
    } else {
      await _databaseHelper.createProductCategory(c);
      _categoriesPrivate.add(c);
      notifyListeners();
    }
  }

  Future<void> processNfceItems(Nfce nfce) async {}

  double get totalReceitas =>
      receipts.fold(0.0, (s, x) => s + x.value);

  double get totalDespesas =>
      expenses.fold(0.0, (s, x) => s + x.value);

  double get totalReceitasAtuais =>
      receipts.where((x) => !x.isFuture).fold(0.0, (s, x) => s + x.value);

  double get totalDespesasAtuais =>
      expenses.where((x) => !x.isFuture).fold(0.0, (s, x) => s + x.value);

  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;

  void forceNotify() => notifyListeners();

  Future<void> updateDisplayName(String newName) async {
    if (_firestoreService != null) {
      await _firestoreService!.updateUserName(newName);
      _userName = newName;
      notifyListeners();
    }
  }
}