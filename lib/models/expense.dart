import 'package:flutter/material.dart';
import 'expense_category.dart';

class Expense {
  final String title;
  final double value;
  final ExpenseCategory category;
  final String note;
  final DateTime date;

  Expense({
    required this.title,
    required this.value,
    required this.category,
    required this.note,
    required this.date,
  });

  bool get isFuture => date.isAfter(DateTime.now());
}