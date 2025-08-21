import 'package:flutter/material.dart';
import 'expense.dart';
import 'receipt.dart';

class FinanceState extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final List<Receipt> _receipts = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void addReceipt(Receipt receipt) {
    _receipts.add(receipt);
    notifyListeners();
  }
  double get totalReceitas {
    return receipts.fold(0, (sum, item) => sum + item.value);
  }
}