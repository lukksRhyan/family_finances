import 'package:family_finances/database_helper.dart';
import 'package:flutter/material.dart';
import 'expense.dart';
import 'receipt.dart';
import 'shopping_item.dart';

class FinanceState with ChangeNotifier {
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  final List<ShoppingItem> _shoppingList = [];
  bool _isLoading = false;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Receipt> get receipts => List.unmodifiable(_receipts);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);

  FinanceState(){
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _expenses = await DatabaseHelper.instance.getAllExpenses();
    _receipts = await DatabaseHelper.instance.getAllReceipts();

    _isLoading = false;
    notifyListeners();
  }

  void addExpense(Expense expense) async {
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
    _expenses.insert(0, newExpense);
    notifyListeners();
  }

  void updateExpense(Expense expense) async {
    if (expense.id == null) return;
    await DatabaseHelper.instance.updateExpense(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  void deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
  }

  void addReceipt(Receipt receipt) async {
    final id = await DatabaseHelper.instance.createReceipt(receipt);
    final newReceipt = Receipt(
      id: id,
      title: receipt.title,
      value: receipt.value,
      category: receipt.category,
      date: receipt.date,
      isRecurrent: receipt.isRecurrent,
      recurrencyId: receipt.recurrencyId,
    );
    _receipts.insert(0, newReceipt);
    notifyListeners();
  }

  void updateReceipt(Receipt receipt) async {
    if (receipt.id == null) return;
    await DatabaseHelper.instance.updateReceipt(receipt);
    final index = _receipts.indexWhere((r) => r.id == receipt.id);
    if (index != -1) {
      _receipts[index] = receipt;
      notifyListeners();
    }
  }

  void deleteReceipt(int id) async {
    await DatabaseHelper.instance.deleteReceipt(id);
    _receipts.removeWhere((receipt) => receipt.id == id);
    notifyListeners();
  }

  void addShoppingItem(ShoppingItem item) {
    // Normaliza a descrição para comparação
    String normalize(String s) => s.trim().toLowerCase().replaceAll(' ', '');

    final existing = _shoppingList.firstWhere(
      (element) => normalize(element.name) == normalize(item.name),
      orElse: () => ShoppingItem(name: 'NOT_FOUND'),
    );

    if (existing.name != 'NOT_FOUND') {
      // Mescla as opções, evitando duplicadas
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
    if (index >= 0 && index < shoppingList.length) {
      shoppingList[index] = item;
      notifyListeners();
    }
  }

  void toggleShoppingItemChecked(int index, bool value) {
    _shoppingList[index].isChecked = value;
    notifyListeners();
  }

  double get totalReceitas {
    return receipts.fold(0, (sum, item) => sum + item.value);
  }

  double get totalDespesas {
    return expenses.fold(0, (sum, item) => sum + item.value);
  }

  double get totalReceitasAtuais {
    return receipts.where((r) => !r.isFuture).fold(0, (sum, item) => sum + item.value);
  }

  double get totalDespesasAtuais {
    return expenses.where((e) => !e.isFuture).fold(0, (sum, item) => sum + item.value);
  }

  double get saldoAtual {
    return totalReceitasAtuais - totalDespesasAtuais;
  }
}