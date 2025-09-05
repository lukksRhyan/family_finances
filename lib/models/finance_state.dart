import 'package:family_finances/database_helper.dart';
import 'package:flutter/material.dart';
import 'expense.dart';
import 'receipt.dart';
import 'shopping_item.dart';

class FinanceState with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<ShoppingItem> _shoppingList = [];
  bool _isLoading = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Receipt> get receipts => List.unmodifiable(_receipts);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  bool get isLoading => _isLoading;
  double get totalDespesas => _expenses.fold(0, (sum, item) => sum + item.value);
  double get totalReceitas => _receipts.fold(0, (sum, item) => sum + item.value);
  double get saldo => totalReceitas - totalDespesas;

  FinanceState(){
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _expenses = await DatabaseHelper.instance.getAllExpenses();
    _receipts = await DatabaseHelper.instance.getAllReceipts();
    _shoppingList = await DatabaseHelper.instance.getAllShoppingItems();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final id = await DatabaseHelper.instance.createExpense(expense);
    final newExpense = Expense(
      id: id,
      title: expense.title,
      value: expense.value,
      category: expense.category,
      note: expense.note,
      date: expense.date,
      isRecurrent: expense.isRecurrent,
      recurrencyId: expense.recurrencyId,
      recurrencyType: expense.recurrencyType,
      recurrentIntervalDays: expense.recurrentIntervalDays,
      isInInstallments: expense.isInInstallments,
      installmentCount: expense.installmentCount,
    );
    _expenses.add(newExpense);
    notifyListeners();
  }

  Future<void> addReceipt(Receipt receipt) async {
    final id = await DatabaseHelper.instance.createReceipt(receipt);
    final newReceipt = Receipt(
      id: id,
      title: receipt.title,
      value: receipt.value,
      date: receipt.date,
    );
    _receipts.add(newReceipt);
    notifyListeners();
  }

 void addShoppingItem(ShoppingItem item) {
  String normalize(String s) => s.trim().toLowerCase().replaceAll(' ', '');

  final existingItem = _shoppingList.firstWhere(
    (element) => normalize(element.name) == normalize(item.name),
    orElse: () => ShoppingItem(name: '', options: []),
  );

  if (existingItem.name.isNotEmpty) {
    for (var opt in item.options) {
      bool alreadyExists = existingItem.options.any((o) =>
        o.brand.trim().toLowerCase() == opt.brand.trim().toLowerCase() &&
        o.store.trim().toLowerCase() == opt.store.trim().toLowerCase() &&
        o.price == opt.price
      );
      if (!alreadyExists) {
        existingItem.options.add(opt);
      }
    }
  } else {
    _shoppingList.add(item);
  }
  notifyListeners();
}

void updateShoppingItem(int index, ShoppingItem item) {
  if (index >= 0 && index < _shoppingList.length) {
    // Corrigido: Atualiza a lista privada
    _shoppingList[index] = item;
    notifyListeners();
  }
}

  Future<void> toggleShoppingItemChecked(int index, bool value) async {
    if (index >= 0 && index < _shoppingList.length) {
      final item = _shoppingList[index];
      item.isChecked = value;
      await DatabaseHelper.instance.updateShoppingItem(item);
      notifyListeners();
    }
  }
}