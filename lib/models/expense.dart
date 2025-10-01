import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'expense_category.dart';

class Expense {
  final String? id; // O ID agora pode ser String (do Firestore)
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
    this.id,
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

  // Construtor 'fromMap' atualizado para o Firestore
  static Expense fromMap(Map<String, dynamic> map, {String? id}) {
    return Expense(
      id: id, // Recebe o ID do documento
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      category: ExpenseCategory(
        name: map['category_name'],
        icon: IconData(
          map['category_icon'],
          fontFamily: 'MaterialIcons',
        ),
      ),
      note: map['note'],
      // Converte o Timestamp do Firestore para DateTime
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['is_recurrent'] ?? false,
      recurrencyId: map['recurrency_id'],
      recurrencyType: map['recurrency_type'],
      recurrentIntervalDays: map['recurrent_interval_days'],
      isInInstallments: map['is_in_installments'] ?? false,
      installmentCount: map['installment_count'],
    );
  }

  // Método 'toMap' atualizado para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'note': note,
      'date': Timestamp.fromDate(date), // Converte DateTime para Timestamp
      'is_recurrent': isRecurrent,
      'recurrency_id': recurrencyId,
      'recurrency_type': recurrencyType,
      'recurrent_interval_days': recurrentIntervalDays,
      'is_in_installments': isInInstallments,
      'installment_count': installmentCount,
    };
  }
}