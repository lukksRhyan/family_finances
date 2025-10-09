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
  StreamSubscription? _shoppingListSubscription; // Adicionado

  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<ShoppingItem> _shoppingList = []; // Alterado de 'final'
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

    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _shoppingListSubscription?.cancel(); // Adicionado

    _expensesSubscription = _firestoreService!.getExpensesStream().listen((expenses) {
      _expenses = expenses;
      if (_shoppingListSubscription != null) { // Garante que o loading só termina após o primeiro load
        _isLoading = false;
      }
      notifyListeners();
    });

    _receiptsSubscription = _firestoreService!.getReceiptsStream().listen((receipts) {
      _receipts = receipts;
      notifyListeners();
    });

    // Adicionado: ouve as atualizações da lista de compras
    _shoppingListSubscription = _firestoreService!.getShoppingListStream().listen((shoppingList) {
      _shoppingList = shoppingList;
      if (_expensesSubscription != null) { // Garante que o loading só termina após o primeiro load
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  void _clearData() {
    _firestoreService = null;
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _shoppingListSubscription?.cancel(); // Adicionado
    _expenses = [];
    _receipts = [];
    _shoppingList = []; // Adicionado
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _shoppingListSubscription?.cancel(); // Adicionado
    super.dispose();
  }

  // --- Funções para a Lista de Compras (Agora compatíveis) ---

  Future<void> addShoppingItem(ShoppingItem item) async {
    await _firestoreService?.addShoppingItem(item);
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    await _firestoreService?.updateShoppingItem(item);
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _firestoreService?.deleteShoppingItem(itemId);
  }

  Future<void> toggleShoppingItemChecked(ShoppingItem item, bool value) async {
    final updatedItem = ShoppingItem(
      id: item.id,
      name: item.name,
      isChecked: value,
      options: item.options,
    );
    await _firestoreService?.updateShoppingItem(updatedItem);
  }


  // --- Funções de Despesas e Receitas (sem alterações) ---
  Future<void> addExpense(Expense expense) async => await _firestoreService?.addExpense(expense);
  Future<void> updateExpense(Expense expense) async => await _firestoreService?.updateExpense(expense);
  Future<void> deleteExpense(String id) async => await _firestoreService?.deleteExpense(id);
  Future<void> addReceipt(Receipt receipt) async => await _firestoreService?.addReceipt(receipt);
  Future<void> updateReceipt(Receipt receipt) async => await _firestoreService?.updateReceipt(receipt);
  Future<void> deleteReceipt(String id) async => await _firestoreService?.deleteReceipt(id);


  // --- Getters (sem alterações) ---
  double get totalReceitas => receipts.fold(0, (sum, item) => sum + item.value);
  double get totalDespesas => expenses.fold(0, (sum, item) => sum + item.value);
  double get totalReceitasAtuais => receipts.where((r) => !r.isFuture).fold(0, (sum, item) => sum + item.value);
  double get totalDespesasAtuais => expenses.where((e) => !e.isFuture).fold(0, (sum, item) => sum + item.value);
  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;
}