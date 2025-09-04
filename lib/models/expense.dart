import 'package:flutter/material.dart';

import 'expense_category.dart';

class Expense {
  final int? id;
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
    this.id,
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

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'categoryName': category.name,
      'categoryIcon': category.icon.codePoint,
      'note': note,
      'date': date.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'recurrencyId': recurrencyId,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
      'isInInstallments': isInInstallments ? 1 : 0,
      'installmentCount': installmentCount,
    };
  }

  // Cria um objeto Expense a partir de um Map do banco de dados
  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id:map['id'],
      title: map['title'],
      value: map['value'],
      category: ExpenseCategory(name: map['categoryName'], icon: IconData(map['categoryIcon'], fontFamily: 'MaterialIcons')),
      note: map['note'],
      date: DateTime.parse(map['date']),
      isRecurrent: map['isRecurrent'] == 1,
      recurrencyId: map['recurrencyId'],
      recurrencyType: map['recurrencyType'],
      recurrentIntervalDays: map['recurrentIntervalDays'],
      isInInstallments: map['isInInstallments'] == 1,
      installmentCount: map['installmentCount'],
    );
  }

}