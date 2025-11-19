import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/app_categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../database_helper.dart';
import 'expense.dart';
import 'receipt.dart';
import 'product.dart';
import 'product_category.dart';
import 'expense_category.dart';
import 'nfce.dart';

class FinanceState with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  late GeminiService _geminiService;

  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Receipt>>? _receiptsSubscription;
  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<List<ProductCategory>>? _productCategoriesSubscription;

  String? _uid;
  bool _isLoading = true;

  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Product> _products = [];
  List<ProductCategory> _productCategories = [];

  final List<ExpenseCategory> _expenseCategories = AppCategories.expenseCategories;

  bool get isLoggedIn => _uid != null;

  List<Expense> get expenses {
    final c = List<Expense>.from(_expenses);
    c.sort((a, b) => b.date.compareTo(a.date));
    return c;
  }

  List<Receipt> get receipts {
    final c = List<Receipt>.from(_receipts);
    c.sort((a, b) => b.date.compareTo(a.date));
    return c;
  }

  List<Product> get shoppingListProducts => _products;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  FinanceState() {
    _geminiService = GeminiService();
    FirebaseAuth.instance.authStateChanges().listen((u) {
      _handleAuthStateChanged(u);
    });
    _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }

  void _handleAuthStateChanged(User? user) {
    if (user != null && _uid != user.uid) {
      _uid = user.uid;
      _initializeCloudData(user.uid);
    } else if (user == null && _uid != null) {
      _uid = null;
      _initializeLocalData();
    } else if (user == null && _uid == null) {
      if (_expenses.isEmpty && _receipts.isEmpty && _products.isEmpty) {
        _initializeLocalData();
      }
    }
  }

  Future<void> _initializeLocalData() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    await _clearCloudSubscriptions();
    _firestoreService = null;

    try {
      _expenses = await _databaseHelper.getAllExpenses();
      _receipts = await _databaseHelper.getAllReceipts();
      _productCategories = await _databaseHelper.getAllProductCategories();
      _products = await _databaseHelper.getAllProducts();
    } catch (_) {
      _expenses = [];
      _receipts = [];
      _productCategories = [];
      _products = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initializeCloudData(String uid) {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _firestoreService = FirestoreService(uid: uid);
    _clearCloudSubscriptions();

    int streamsToLoad = 4;
    int loaded = 0;

    void ok() {
      loaded++;
      if (loaded >= streamsToLoad) _isLoading = false;
      notifyListeners();
    }

    _expensesSubscription =
        _firestoreService!.getExpensesStream().listen((d) {
      _expenses = d;
      ok();
    }, onError: (_) => ok());

    _receiptsSubscription =
        _firestoreService!.getReceiptsStream().listen((d) {
      _receipts = d;
      ok();
    }, onError: (_) => ok());

    _productsSubscription =
        _firestoreService!.getProductsStream().listen((d) {
      _products = d;
      ok();
    }, onError: (_) => ok());

    _productCategoriesSubscription =
        _firestoreService!.getCategoriesStream().listen((d) {
      _productCategories = [ProductCategory.indefinida, ...d];
      ok();
    }, onError: (_) => ok());
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

  Future<void> addExpense(Expense e) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addExpense(e);
    } else {
      final created = await _databaseHelper.createExpense(e);
      _expenses.insert(0, created.copyWith(localId: created.localId));
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense e) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateExpense(e);
    } else {
      await _databaseHelper.updateExpense(e);
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

  Future<void> addReceipt(Receipt r) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addReceipt(r);
    } else {
      final created = await _databaseHelper.createReceipt(r);
      _receipts.insert(0, created.copyWith(localId: created.localId));
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt r) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateReceipt(r);
    } else {
      await _databaseHelper.updateReceipt(r);
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

  Future<void> addProduct(Product p) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProduct(p);
    } else {
      final created = await _databaseHelper.createProduct(p);
      _products.add(created.copyWith(localId: created.localId));
      _products.sort((a, b) => a.nameLower.compareTo(b.nameLower));
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product p) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateProduct(p);
    } else {
      await _databaseHelper.updateProduct(p);
      _products = await _databaseHelper.getAllProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.deleteProduct(id);
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteProduct(localId);
      _products.removeWhere((p) => p.localId == localId);
      notifyListeners();
    }
  }

  Future<void> toggleProductChecked(Product p, bool v) async {
    final updated = p.copyWith(isChecked: v);
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.updateProduct(updated);
    } else {
      await _databaseHelper.updateProduct(updated);
      final i = _products.indexWhere((x) => x.localId == updated.localId);
      if (i != -1) {
        _products[i] = updated;
        notifyListeners();
      }
    }
  }

  Future<void> addProductCategory(ProductCategory c) async {
    if (isLoggedIn && _firestoreService != null) {
      await _firestoreService!.addProductCategory(c);
    } else {
      await _databaseHelper.createProductCategory(c);
      _productCategories.add(c);
      notifyListeners();
    }
  }

  Future<void> syncLocalDataToFirebase(String newUid) async {
    if (_firestoreService == null || _firestoreService!.uid != newUid) {
      _firestoreService = FirestoreService(uid: newUid);
    }

    final localExpenses = await _databaseHelper.getAllExpenses();
    final localReceipts = await _databaseHelper.getAllReceipts();
    final localCategories = await _databaseHelper.getAllProductCategories();
    final localProducts = await _databaseHelper.getAllProducts();

    for (final c in localCategories) {
      await _firestoreService!.addProductCategory(c);
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

    await _databaseHelper.deleteAllLocalData();
  }

  Future<void> _loadAllDataFromSqlite() async {
    _expenses = await _databaseHelper.getAllExpenses();
    _receipts = await _databaseHelper.getAllReceipts();
    _products = await _databaseHelper.getAllProducts();
    _productCategories = await _databaseHelper.getAllProductCategories();
    notifyListeners();
  }

  double get totalReceitas =>
      receipts.fold(0.0, (s, r) => s + r.value);

  double get totalDespesas =>
      expenses.fold(0.0, (s, e) => s + e.value);

  double get totalReceitasAtuais =>
      receipts.where((r) => !r.isFuture).fold(0.0, (s, r) => s + r.value);

  double get totalDespesasAtuais =>
      expenses.where((e) => !e.isFuture).fold(0.0, (s, e) => s + e.value);

  double get saldoAtual =>
      totalReceitasAtuais - totalDespesasAtuais;

  Future<void> processNfceItems(Nfce n) async {}

  void forceNotify() => notifyListeners();
}
