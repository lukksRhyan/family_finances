import 'expense_category.dart';

class Expense {
  final String title;
  final double value;
  final ExpenseCategory category;
  final String note;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyId;
  final int? recurrencyType; // This will store the recurrence type (e.g., monthly, weekly, custom)
  final int? recurrentIntervalDays; // This will store the custom interval in days
  final bool isInInstallments;
  final int? installmentCount;

  Expense({
    required this.title,
    required this.value,
    required this.category,
    required this.note,
    required this.date,
    required this.isRecurrent,
    this.recurrencyId,
    this.recurrencyType,
    this.recurrentIntervalDays, // Add the new field
    required this.isInInstallments,
    this.installmentCount,
  });

  bool get isFuture => date.isAfter(DateTime.now());
}