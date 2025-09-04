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

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void addReceipt(Receipt receipt) {
    _receipts.add(receipt);
    notifyListeners();
  }

  void addShoppingItem(ShoppingItem item) {
    // Normaliza a descrição para comparação
    String normalize(String s) => s.trim().toLowerCase().replaceAll(' ', '');

    final existingList = _shoppingList.where(
      (i) => normalize(i.name) == normalize(item.name),
    ).toList();

    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      // Adiciona novas opções ao item existente, evitando duplicadas
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

  double get totalAReceber {
    return receipts.where((r) => r.isFuture).fold(0, (sum, item) => sum + item.value);
  }

  double get totalAPagar {
    return expenses.where((e) => e.isFuture).fold(0, (sum, item) => sum + item.value);
  }
}