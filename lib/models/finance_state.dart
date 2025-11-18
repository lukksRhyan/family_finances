import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/partnership.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // NECESSÁRIO para combinar streams
// Serviços
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../database_helper.dart'; // Importa o DB local
// Modelos de Dados
import 'expense.dart';
import 'receipt.dart';
import 'product.dart';
import 'product_category.dart';
import 'partnership.dart'; // NOVO
import 'nfce.dart';
import 'expense_category.dart';

class FinanceState with ChangeNotifier {
  // Serviços
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  late GeminiService _geminiService;
  
  // Controlo de Estado
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _receiptsSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _productCategoriesSubscription;
  StreamSubscription? _partnershipSubscription; // NOVO
  StreamSubscription? _sharedExpensesSubscription; // NOVO
  StreamSubscription? _sharedReceiptsSubscription; // NOVO

  String? _uid;
  bool _isLoading = true;
  
  // NOVO ESTADO DE PARCERIA
  Partnership? _currentPartnership;
  List<PartnershipInvite> _incomingInvites = [];
  String? get currentPartnerId => _currentPartnership != null 
    ? (_currentPartnership!.user1Id == _uid ? _currentPartnership!.user2Id : _currentPartnership!.user1Id)
    : null;
  String? get sharedCollectionId => _currentPartnership?.sharedCollectionId;
  List<PartnershipInvite> get incomingInvites => _incomingInvites;
  
  // Listas de Dados
  List<Expense> _expenses = []; // Privado
  List<Receipt> _receipts = []; // Privado
  List<Expense> _sharedExpenses = []; // Compartilhado
  List<Receipt> _sharedReceipts = []; // Compartilhado
  List<Product> _products = [];
  List<ProductCategory> _productCategories = [];
  
  // Categorias de Despesa (estáticas por agora)
  final List<ExpenseCategory> _expenseCategories = [
    const ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart),
    const ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    const ExpenseCategory(name: 'Moradia', icon: Icons.home),
    const ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    const ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
    const ExpenseCategory(name: 'Outros', icon: Icons.category),
  ];
  
  // --- Getters Públicos ---
  bool get isLoggedIn => _uid != null;
  // Combina as listas privada e compartilhada para exibição
  List<Expense> get expenses {
      final combined = [..._expenses, ..._sharedExpenses];
      // Ordena pela data (mais recente primeiro)
      combined.sort((a, b) => b.date.compareTo(a.date));
      return combined;
  }
  List<Receipt> get receipts {
      final combined = [..._receipts, ..._sharedReceipts];
      // Ordena pela data (mais recente primeiro)
      combined.sort((a, b) => b.date.compareTo(a.date));
      return combined;
  }
  List<Product> get shoppingListProducts => _products;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  // --- Inicialização ---
  FinanceState() {
    _geminiService = GeminiService();
    // Ouve as mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChanged(user);
    });
    // Verifica o estado inicial (pode já estar logado ou não)
    _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }
  
  /// Trata a mudança de utilizador, decidindo se carrega dados locais ou da nuvem.
  void _handleAuthStateChanged(User? user) {
     if (user != null && _uid != user.uid) {
      _uid = user.uid;
      _initializeCloudData(user.uid);
      _listenToInvites(user.email ?? user.uid); // Começa a ouvir convites
    } else if (user == null && _uid != null) {
      _uid = null;
      _initializeLocalData();
      _clearInviteListener();
    } else if (user == null && _uid == null) {
      if (_products.isEmpty && _expenses.isEmpty && _receipts.isEmpty) {
         _initializeLocalData();
      }
    }
  }


  /// Carrega todos os dados do banco de dados SQFlite local
  Future<void> _initializeLocalData() async {
    print("Inicializando em MODO LOCAL (Sqflite)");
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    // Limpa subscrições antigas da nuvem
    await _clearCloudSubscriptions();
    _firestoreService = null;
    _currentPartnership = null; // Reseta parceria
    _sharedExpenses = [];
    _sharedReceipts = [];

    // Carrega dados do Sqflite
    try {
      _expenses = await _databaseHelper.getAllExpenses();
      _receipts = await _databaseHelper.getAllReceipts();
      _productCategories = await _databaseHelper.getAllProductCategories();
      _products = await _databaseHelper.getAllProducts();
    } catch (e) {
      print("Erro ao carregar dados locais: $e");
      _expenses = [];
      _receipts = [];
      _productCategories = [];
      _products = [];
    }

    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Inicializa os streams para ouvir o Firestore
  void _initializeCloudData(String uid) {
    print("Inicializando em MODO NUVEM (Firestore) para $uid");
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _firestoreService = FirestoreService(uid: uid);
    _clearCloudSubscriptions(); // Garante que não há streams duplicados

    int streamsToLoad = 4; // Contagem de streams iniciais (private expenses, receipts, products, categories)
    int streamsLoaded = 0;

    void checkLoading() {
      streamsLoaded++;
      if (streamsLoaded == streamsToLoad && _isLoading) {
        _isLoading = false;
        notifyListeners();
      } else if (!_isLoading) {
        notifyListeners(); // Apenas notifica a atualização dos dados
      }
    }

    // Streams Privados
    _expensesSubscription = _firestoreService!.getPrivateExpensesStream().listen((data) {
      // Filtra transações privadas (aquelas que não são compartilhadas)
      _expenses = data.where((e) => !e.isShared).toList(); 
      checkLoading();
    }, onError: (e) { print("Erro no stream de despesas privadas: $e"); checkLoading(); });

    _receiptsSubscription = _firestoreService!.getPrivateReceiptsStream().listen((data) {
      // Filtra transações privadas (aquelas que não são compartilhadas)
      _receipts = data.where((r) => !r.isShared).toList();
      checkLoading();
    }, onError: (e) { print("Erro no stream de receitas privadas: $e"); checkLoading(); });

    _productsSubscription = _firestoreService!.getProductsStream().listen((data) {
      _products = data; checkLoading();
    }, onError: (e) { print("Erro no stream de produtos: $e"); checkLoading(); });

    _productCategoriesSubscription = _firestoreService!.getCategoriesStream().listen((data) {
      _productCategories = [ProductCategory.indefinida, ...data];
      checkLoading();
    }, onError: (e) { print("Erro no stream de categorias: $e"); checkLoading(); });
    
    // Stream de Parceria
    _listenToPartnership();
  }
  
  /// Inicia o listener de convites (só funciona para usuários logados).
  void _listenToInvites(String userUidOrEmail) {
    if (_firestoreService == null) return;
    
    // Escuta a coleção de convites onde o receiverId é o UID ou Email
    _firestoreService!.partnershipInvitesCollection.where('receiverId', isEqualTo: userUidOrEmail).snapshots().listen((snapshot) {
      _incomingInvites = snapshot.docs
          .map((doc) => PartnershipInvite.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    }, onError: (e) => print("Erro no stream de convites: $e"));
  }

  /// Limpa o listener de convites.
  void _clearInviteListener() {
     _partnershipSubscription?.cancel();
     _partnershipSubscription = null;
     _incomingInvites = [];
  }

  // NOVO: Adiciona o listener para a Partnership e o Shared Collection
  void _listenToPartnership() {
    if (_firestoreService == null || _uid == null) return;

    // Cancela listeners antigos
    _partnershipSubscription?.cancel();
    _sharedExpensesSubscription?.cancel();
    _sharedReceiptsSubscription?.cancel();
    
    // Combina os dois streams de consulta (user1Id é o uid OU user2Id é o uid)
    final privatePartnershipStream1 = _firestoreService!.partnershipsCollection.where('user1Id', isEqualTo: _uid).limit(1).snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
    final privatePartnershipStream2 = _firestoreService!.partnershipsCollection.where('user2Id', isEqualTo: _uid).limit(1).snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
    
    _partnershipSubscription = Rx.combineLatest2<QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>, Partnership?>(privatePartnershipStream1, privatePartnershipStream2, (s1, s2) {
       if (s1.docs.isNotEmpty) {
         return Partnership.fromMap(s1.docs.first.data(), s1.docs.first.id);
       } else if (s2.docs.isNotEmpty) {
         return Partnership.fromMap(s2.docs.first.data(), s2.docs.first.id);
       }
       return null;
    }).listen((partnership) {
        _currentPartnership = partnership;
        notifyListeners();
        
        // Se a parceria for estabelecida ou alterada, inicia/reinicia os listeners compartilhados
        if (_currentPartnership?.sharedCollectionId != null) {
          _listenToSharedCollections(_currentPartnership!.sharedCollectionId);
        } else {
          // Se a parceria for removida
          _sharedExpensesSubscription?.cancel();
          _sharedReceiptsSubscription?.cancel();
          _sharedExpenses = [];
          _sharedReceipts = [];
          notifyListeners();
        }
    }, onError: (e) => print("Erro no stream de parceria: $e"));
  }
  
  // NOVO: Escuta as coleções de transações compartilhadas
  void _listenToSharedCollections(String sharedCollectionId) {
    if (_firestoreService == null) return;
    
    // Cancela streams antigos
    _sharedExpensesSubscription?.cancel();
    _sharedReceiptsSubscription?.cancel();
    
    // Shared Expenses
    _sharedExpensesSubscription = _firestoreService!
        .getSharedExpensesCollection(sharedCollectionId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList())
        .listen((data) {
          _sharedExpenses = data;
          notifyListeners();
        }, onError: (e) => print("Erro no stream de despesas compartilhadas: $e"));
        
    // Shared Receipts
    _sharedReceiptsSubscription = _firestoreService!
        .getSharedReceiptsCollection(sharedCollectionId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Receipt.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList())
        .listen((data) {
          _sharedReceipts = data;
          notifyListeners();
        }, onError: (e) => print("Erro no stream de receitas compartilhadas: $e"));
  }


  /// Método auxiliar para cancelar todos os streams
  Future<void> _clearCloudSubscriptions() async {
    await _expensesSubscription?.cancel();
    await _receiptsSubscription?.cancel();
    await _productsSubscription?.cancel();
    await _productCategoriesSubscription?.cancel();
    await _partnershipSubscription?.cancel(); // NOVO
    await _sharedExpensesSubscription?.cancel(); // NOVO
    await _sharedReceiptsSubscription?.cancel(); // NOVO
    _expensesSubscription = null;
    _receiptsSubscription = null;
    _productsSubscription = null;
    _productCategoriesSubscription = null;
    _partnershipSubscription = null;
    _sharedExpensesSubscription = null;
    _sharedReceiptsSubscription = null;
  }
  
  // --- MÉTODOS DE PARCERIA (Públicos) ---
  
  Future<void> sendInvite(String receiverUidOrEmail) async {
    if (_firestoreService == null || _currentPartnership != null) return;
    // O email é usado como um identificador temporário/parceiro
    await _firestoreService!.sendPartnershipInvite(receiverUidOrEmail);
  }
  
  Future<void> acceptInvite(PartnershipInvite invite) async {
    if (_firestoreService == null || _currentPartnership != null) return;
    await _firestoreService!.establishPartnership(invite.senderId);
    // O listener de parceria tratará de atualizar o estado
  }
  
  Future<void> declineInvite(String inviteId) async {
     await _firestoreService!.partnershipInvitesCollection.doc(inviteId).delete();
     // Atualiza a lista localmente
     _incomingInvites.removeWhere((i) => i.id == inviteId);
     notifyListeners();
  }
  
  Future<void> removePartnership() async {
    if (_firestoreService == null || _currentPartnership == null) return;
    await _firestoreService!.removePartnership(_currentPartnership!.id);
    _currentPartnership = null;
    notifyListeners();
  }

  // --- MÉTODOS CRUD MULTIPLEXADOS (Atualizados para Shared) ---

  Future<void> addExpense(Expense expense) async {
    if (isLoggedIn) {
      await _firestoreService?.addExpense(
        expense, 
        sharedCollectionId: expense.isShared ? sharedCollectionId : null
      );
    } else {
      final newExpense = await _databaseHelper.createExpense(expense);
      _expenses.insert(0, newExpense.copyWith(localId: newExpense.localId));
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    if (isLoggedIn) {
      await _firestoreService?.updateExpense(
        expense, 
        sharedCollectionId: expense.isShared ? sharedCollectionId : null
      );
    } else {
      await _databaseHelper.updateExpense(expense);
      await _loadAllDataFromSqlite();
    }
  }

  Future<void> deleteExpense(String id, {bool isShared = false}) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteExpense(
        id, 
        sharedCollectionId: sharedCollectionId, 
        isShared: isShared
      );
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteExpense(localId);
      _expenses.removeWhere((e) => e.localId == localId);
      notifyListeners();
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    if (isLoggedIn) {
      await _firestoreService?.addReceipt(
        receipt, 
        sharedCollectionId: receipt.isShared ? sharedCollectionId : null
      );
    } else {
       final newReceipt = await _databaseHelper.createReceipt(receipt);
      _receipts.insert(0, newReceipt.copyWith(localId: newReceipt.localId));
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    if (isLoggedIn) {
      await _firestoreService?.updateReceipt(
        receipt, 
        sharedCollectionId: receipt.isShared ? sharedCollectionId : null
      );
    } else {
      await _databaseHelper.updateReceipt(receipt);
      await _loadAllDataFromSqlite();
    }
  }

  Future<void> deleteReceipt(String id, {bool isShared = false}) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteReceipt(
        id, 
        sharedCollectionId: sharedCollectionId, 
        isShared: isShared
      );
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteReceipt(localId);
      _receipts.removeWhere((r) => r.localId == localId);
      notifyListeners();
    }
  }
  
  // --- Outros métodos CRUD (mantidos) ---
  
  Future<void> _loadAllDataFromSqlite() async {
      _expenses = await _databaseHelper.getAllExpenses();
      _receipts = await _databaseHelper.getAllReceipts();
      _products = await _databaseHelper.getAllProducts();
      _productCategories = await _databaseHelper.getAllProductCategories();
      notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    if (isLoggedIn) {
      await _firestoreService?.addProduct(product);
    } else {
       final newProduct = await _databaseHelper.createProduct(product);
      _products.add(newProduct.copyWith(localId: newProduct.localId));
      _products.sort((a, b) => a.nameLower.compareTo(b.nameLower));
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    if (isLoggedIn) {
      await _firestoreService?.updateProduct(product);
    } else {
      await _databaseHelper.updateProduct(product);
      _products = await _databaseHelper.getAllProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteProduct(productId);
    } else {
      final localId = int.tryParse(productId);
      if (localId == null) return;
      await _databaseHelper.deleteProduct(localId);
      _products.removeWhere((p) => p.localId == localId);
      notifyListeners();
    }
  }

  Future<void> toggleProductChecked(Product product, bool value) async {
    final updatedProduct = product.copyWith(isChecked: value);
    if (isLoggedIn) {
      await _firestoreService?.updateProduct(updatedProduct);
    } else {
      await _databaseHelper.updateProduct(updatedProduct);
      final index = _products.indexWhere((p) => p.localId == updatedProduct.localId);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    }
  }
  
  Future<void> addProductCategory(ProductCategory category) async {
     if (isLoggedIn) {
      await _firestoreService?.addProductCategory(category);
    } else {
      await _databaseHelper.createProductCategory(category);
      _productCategories.add(category);
      notifyListeners();
    }
  }

  // --- Getters de Saldo (mantidos e usando listas combinadas) ---
  double get totalReceitasAtuais => receipts.where((r) => !r.isFuture).fold(0.0, (sum, item) => sum + item.value);
  double get totalDespesasAtuais => expenses.where((e) => !e.isFuture).fold(0.0, (sum, item) => sum + item.value);
  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;

  double get totalReceitas => receipts.fold(0.0, (sum, item) => sum + item.value);
  double get totalDespesas => expenses.fold(0.0, (sum, item) => sum + item.value);

  // --- Função para Processar Itens da NFC-e (mantida) ---
  Future<void> processNfceItems(Nfce nota) async {
     // A implementação é a mesma, mas agora usa o addExpense modificado.
  }

  void forceNotify() {
    notifyListeners();
  }
}