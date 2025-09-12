import 'package:flutter/material.dart';
import 'expense_category.dart';

class Expense {
  final int? id; // Adicionado para guardar o ID do banco de dados
  final String title;
  final double value;
  final ExpenseCategory category;
  final String note;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyId;
  final int? recurrencyType;
  final int? recurrentIntervalDays;
  final bool isInInstallments;
  final int? installmentCount;

  Expense({
    this.id, // O ID pode ser nulo se for uma nova despesa
    required this.title,
    required this.value,
    required this.category,
    required this.note,
    required this.date,
    required this.isRecurrent,
    this.recurrencyId,
    this.recurrencyType,
    this.recurrentIntervalDays,
    required this.isInInstallments,
    this.installmentCount,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.title == title &&
        other.value == value &&
        other.date == date &&
        other.isRecurrent == isRecurrent;
  }


  static Expense fromMap(Map<String, dynamic> map) {
  return Expense(
    id: map['id'],
    title: map['title'],
    value: map['value'],
    category: ExpenseCategory(
      name: map['category_name'],
      icon: IconData(
        int.tryParse(map['category_icon'].toString()) ?? 0xe360, // Safely parse the string to an int. Use a default icon if parsing fails.
        fontFamily: 'MaterialIcons',
      ),
    ),
    note: map['note'],
    date: DateTime.parse(map['date']),
    isRecurrent: map['is_recurrent'] == 1,
    recurrencyId: map['recurrency_id'],
    recurrencyType: map['recurrency_type'],
    recurrentIntervalDays: map['recurrent_interval_days'],
    isInInstallments: map['is_in_installments'] == 1,
    installmentCount: map['installment_count'],
  );
}

// Correção no método 'toMap' para consistência
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'title': title,
    'value': value,
    'category_name': category.name,
    'category_icon': category.icon.codePoint.toString(), // Explicitly save the code point as a string
    'note': note,
    'date': date.toIso8601String(),
    'is_recurrent': isRecurrent ? 1 : 0,
    'recurrency_id': recurrencyId,
    'recurrency_type': recurrencyType,
    'recurrent_interval_days': recurrentIntervalDays,
    'is_in_installments': isInInstallments ? 1 : 0,
    'installment_count': installmentCount,
  };
}
}