import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'expense.dart';
import 'receipt.dart';
import 'shopping_item.dart';

class FinanceState with ChangeNotifier {
  FirestoreService? _firestoreService;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _receiptsSubscription;

  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  final List<ShoppingItem> _shoppingList = [];
  bool _isLoading = true;

  List<Expense> get expenses => _expenses;
  List<Receipt> get receipts => _receipts;
  List<ShoppingItem> get shoppingList => _shoppingList;
  bool get isLoading => _isLoading;

  FinanceState() {
    // Ouve as mudanças de autenticação para iniciar ou limpar os dados
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initializeData(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void _initializeData(String uid) {
    _firestoreService = FirestoreService(uid: uid);
    _isLoading = true;
    notifyListeners();

    // Cancela subscrições antigas se existirem
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();

    _expensesSubscription = _firestoreService!.getExpensesStream().listen((expenses) {
      _expenses = expenses;
      _isLoading = false;
      notifyListeners();
    });

    _receiptsSubscription = _firestoreService!.getReceiptsStream().listen((receipts) {
      _receipts = receipts;
      notifyListeners();
    });
  }

  void _clearData() {
    _firestoreService = null;
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _expenses = [];
    _receipts = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    super.dispose();
  }

  // As funções agora simplesmente chamam o serviço do Firestore
  Future<void> addExpense(Expense expense) async {
    await _firestoreService?.addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestoreService?.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _firestoreService?.deleteExpense(id);
  }

  Future<void> addReceipt(Receipt receipt) async {
    await _firestoreService?.addReceipt(receipt);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    await _firestoreService?.updateReceipt(receipt);
  }

  Future<void> deleteReceipt(String id) async {
    await _firestoreService?.deleteReceipt(id);
  }

  // A lógica da lista de compras permanece local por enquanto
  void addShoppingItem(ShoppingItem item) {
    String normalize(String s) => s.trim().toLowerCase().replaceAll(' ', '');
    final existing = _shoppingList.firstWhere(
      (element) => normalize(element.name) == normalize(item.name),
      orElse: () => ShoppingItem(name: 'NOT_FOUND'),
    );
    if (existing.name != 'NOT_FOUND') {
      for (var opt in item.options) {
        bool alreadyExists = existing.options.any((o) =>
          o.brand.trim().toLowerCase() == opt.brand.trim().toLowerCase() &&
          o.store.trim().toLowerCase() == opt.store.trim().toLowerCase() &&
          o.price == opt.price
        );
        if (!alreadyExists) {
          existing.options.add(opt);
        }
      }
    } else {
      _shoppingList.add(item);
    }
    notifyListeners();
  }

  void updateShoppingItem(int index, ShoppingItem item) {
    if (index >= 0 && index < _shoppingList.length) {
      _shoppingList[index] = item;
      notifyListeners();
    }
  }

  void toggleShoppingItemChecked(int index, bool value) {
    _shoppingList[index].isChecked = value;
    notifyListeners();
  }

  // Os getters permanecem os mesmos
  double get totalReceitas => receipts.fold(0, (sum, item) => sum + item.value);
  double get totalDespesas => expenses.fold(0, (sum, item) => sum + item.value);
  double get totalReceitasAtuais => receipts.where((r) => !r.isFuture).fold(0, (sum, item) => sum + item.value);
  double get totalDespesasAtuais => expenses.where((e) => !e.isFuture).fold(0, (sum, item) => sum + item.value);
  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;
}
