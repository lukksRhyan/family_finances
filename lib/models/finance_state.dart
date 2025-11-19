// lib/models/finance_state.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Serviços
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../database_helper.dart';

// Modelos de Dados
import 'expense.dart';
import 'receipt.dart';
import 'product.dart';
import 'product_category.dart';
import 'expense_category.dart';
import 'nfce.dart';

class FinanceState with ChangeNotifier {
  // Serviços
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  late GeminiService _geminiService;

  // Subscriptions
  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Receipt>>? _receiptsSubscription;
  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<List<ProductCategory>>? _productCategoriesSubscription;

  String? _uid;
  bool _isLoading = true;

  // Dados locais (privados)
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Product> _products = [];
  List<ProductCategory> _productCategories = [];

  // Categorias estáticas de despesas (fallback)
  final List<ExpenseCategory> _expenseCategories = [
    const ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart),
    const ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    const ExpenseCategory(name: 'Moradia', icon: Icons.home),
    const ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    const ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
    const ExpenseCategory(name: 'Outros', icon: Icons.category),
  ];

  // --- Getters ---
  bool get isLoggedIn => _uid != null;

  // Expondo listas (privadas apenas; se futuramente quiser mesclar com "shared", faz-se aqui)
  List<Expense> get expenses {
    final copy = List<Expense>.from(_expenses);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<Receipt> get receipts {
    final copy = List<Receipt>.from(_receipts);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<Product> get shoppingListProducts => _products;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  // --- Inicialização ---
  FinanceState() {
    _geminiService = GeminiService();
    // Ouvimos alterações de autenticação
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChanged(user);
    });
    // Checagem inicial
    _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }

  void _handleAuthStateChanged(User? user) {
    // evita reloads desnecessários
    if (user != null && _uid != user.uid) {
      _uid = user.uid;
      _initializeCloudData(user.uid);
    } else if (user == null && _uid != null) {
      // logout
      _uid = null;
      _initializeLocalData();
    } else if (user == null && _uid == null) {
      // primeiro boot em modo local
      if (_expenses.isEmpty && _receipts.isEmpty && _products.isEmpty) {
        _initializeLocalData();
      }
    }
  }

  // --- Modo Local (Sqflite) ---
  Future<void> _initializeLocalData() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    // Cancela streams da nuvem se existirem
    await _clearCloudSubscriptions();
    _firestoreService = null;

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

    _isLoading = false;
    notifyListeners();
  }

  // --- Modo Nuvem (Firestore) ---
  void _initializeCloudData(String uid) {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _firestoreService = FirestoreService(uid: uid);
    _clearCloudSubscriptions();

    int streamsToLoad = 4;
    int streamsLoaded = 0;

    void checkLoading() {
      streamsLoaded++;
      if (streamsLoaded >= streamsToLoad) {
        _isLoading = false;
      }
      notifyListeners();
    }

    // NOTE: usa os nomes de método existentes no seu FirestoreService fornecido
    _expensesSubscription = _firestoreService!.getExpensesStream().listen((data) {
      // Caso seus documentos tenham campo 'isShared', e você queira filtrar,
      // faça aqui. Atualmente assumimos que getExpensesStream devolve só as despesas do usuário.
      _expenses = data;
      checkLoading();
    }, onError: (e) {
      print("Erro no stream de despesas: $e");
      checkLoading();
    });

    _receiptsSubscription = _firestoreService!.getReceiptsStream().listen((data) {
      _receipts = data;
      checkLoading();
    }, onError: (e) {
      print("Erro no stream de receitas: $e");
      checkLoading();
    });

    _productsSubscription = _firestoreService!.getProductsStream().listen((data) {
      _products = data;
      checkLoading();
    }, onError: (e) {
      print("Erro no stream de produtos: $e");
      checkLoading();
    });

    _productCategoriesSubscription = _firestoreService!.getCategoriesStream().listen((data) {
      // garante categoria indefinida no topo
      _productCategories = [ProductCategory.indefinida, ...data];
      checkLoading();
    }, onError: (e) {
      print("Erro no stream de categorias: $e");
      checkLoading();
    });
  }

  Future<void> _clearCloudSubscriptions() async {
    await _expensesSubscription?.cancel();
    await _receiptsSubscription?.cancel();
    await _productsSubscription?.cancel();
    await _productCategoriesSubscription?.cancel();

    _expensesSubscription = null;
    _receiptsSubscription = null;
    _productsSubscription = null;
    _productCategoriesSubscription = null;
  }

  @override
  void dispose() {
    _clearCloudSubscriptions();
    super.dispose();
  }

  // --- CRUD multipath (local / cloud) ---

  Future<void> addExpense(Expense expense) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addExpense(expense);
      // stream do Firestore irá atualizar a lista
    } else {
      final newExpense = await _databaseHelper.createExpense(expense);
      _expenses.insert(0, newExpense.copyWith(localId: newExpense.localId));
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateExpense(expense);
    } else {
      await _databaseHelper.updateExpense(expense);
      await _loadAllDataFromSqlite();
    }
  }

  Future<void> deleteExpense(String id) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteExpense(id);
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteExpense(localId);
      _expenses.removeWhere((e) => e.localId == localId);
      notifyListeners();
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addReceipt(receipt);
    } else {
      final newReceipt = await _databaseHelper.createReceipt(receipt);
      _receipts.insert(0, newReceipt.copyWith(localId: newReceipt.localId));
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateReceipt(receipt);
    } else {
      await _databaseHelper.updateReceipt(receipt);
      await _loadAllDataFromSqlite();
    }
  }

  Future<void> deleteReceipt(String id) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteReceipt(id);
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteReceipt(localId);
      _receipts.removeWhere((r) => r.localId == localId);
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProduct(product);
    } else {
      final newProduct = await _databaseHelper.createProduct(product);
      _products.add(newProduct.copyWith(localId: newProduct.localId));
      _products.sort((a, b) => a.nameLower.compareTo(b.nameLower));
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateProduct(product);
    } else {
      await _databaseHelper.updateProduct(product);
      _products = await _databaseHelper.getAllProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteProduct(productId);
    } else {
      final localId = int.tryParse(productId);
      if (localId == null) return;
      await _databaseHelper.deleteProduct(localId);
      _products.removeWhere((p) => p.localId == localId);
      notifyListeners();
    }
  }

  Future<void> toggleProductChecked(Product product, bool value) async {
    final updated = product.copyWith(isChecked: value);
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateProduct(updated);
    } else {
      await _databaseHelper.updateProduct(updated);
      final idx = _products.indexWhere((p) => p.localId == updated.localId);
      if (idx != -1) {
        _products[idx] = updated;
        notifyListeners();
      }
    }
  }

  Future<void> addProductCategory(ProductCategory category) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProductCategory(category);
    } else {
      await _databaseHelper.createProductCategory(category);
      _productCategories.add(category);
      notifyListeners();
    }
  }

  // --- Utilitários / sincronização local -> cloud (opcional) ---

  Future<void> syncLocalDataToFirebase(String newUid) async {
    if (_firestoreService == null || _firestoreService!.uid != newUid) {
      _firestoreService = FirestoreService(uid: newUid);
    }

    final localExpenses = await _databaseHelper.getAllExpenses();
    final localReceipts = await _databaseHelper.getAllReceipts();
    final localCategories = await _databaseHelper.getAllProductCategories();
    final localProducts = await _databaseHelper.getAllProducts();

    // Envia categorias -> produtos -> transações (ordem simples)
    for (final cat in localCategories) {
      // evitar reenvio de categorias default se necessário
      await _firestoreService!.addProductCategory(cat);
    }

    for (final p in localProducts) {
      await _firestoreService!.addProduct(p);
    }

    for (final e in localExpenses) {
      await _firestoreService!.addExpense(e);
    }

    for (final r in localReceipts) {
      await _firestoreService!.addReceipt(r);
    }

    // apaga local (opcional)
    await _databaseHelper.deleteAllLocalData();
  }

  Future<void> _loadAllDataFromSqlite() async {
    _expenses = await _databaseHelper.getAllExpenses();
    _receipts = await _databaseHelper.getAllReceipts();
    _products = await _databaseHelper.getAllProducts();
    _productCategories = await _databaseHelper.getAllProductCategories();
    notifyListeners();
  }

  // --- Saldos ---
  double get totalReceitas => receipts.fold(0.0, (sum, r) => sum + r.value);
  double get totalDespesas => expenses.fold(0.0, (sum, e) => sum + e.value);
  double get totalReceitasAtuais => receipts.where((r) => !r.isFuture).fold(0.0, (sum, r) => sum + r.value);
  double get totalDespesasAtuais => expenses.where((e) => !e.isFuture).fold(0.0, (sum, e) => sum + e.value);
  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;

  // --- NFC-e processing stub (use sua implementação existente) ---
  Future<void> processNfceItems(Nfce nota) async {
    // mantenha sua implementação (chamando GeminiService, classificando, criando produtos/despesas)
    // aqui chamamos addProduct / addExpense que já cuidam do multiplex.
    print('processNfceItems called (implemente conforme necessário).');
  }

  // Força notificação (útil para pull-to-refresh)
  void forceNotify() {
    notifyListeners();
  }
}
