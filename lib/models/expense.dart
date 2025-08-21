import 'package:flutter/material.dart';
import 'expense_category.dart';

class Expense {
  final String title;
  final double value;
  final ExpenseCategory category;
  final String note;

  Expense({
    required this.title,
    required this.value,
    required this.category,
    required this.note,
  });
}