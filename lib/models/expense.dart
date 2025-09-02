import 'expense_category.dart';

class Expense {
  final String title;
  final double value;
  final ExpenseCategory category;
  final String note;
  final DateTime date;
  final bool isInInstallments;
  final int? installmentCount;

  Expense({
    required this.title,
    required this.value,
    required this.category,
    required this.note,
    required this.date,
    required this.isInInstallments,
    this.installmentCount,
  });

  bool get isFuture => date.isAfter(DateTime.now());
}