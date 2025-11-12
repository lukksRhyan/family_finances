import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'expense_category.dart';

class Expense {
  final String? id; // O ID agora pode ser String (do Firestore)
  final int? localId;
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
    this.localId,
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
  // Método para converter para Map (útil para Sqflite)
  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': localId, // Usa o localId para o Sqflite
      'title': title,
      'value': value,
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'note': note,
      'date': date.toIso8601String(), // Armazena DateTime como String ISO
      'isRecurrent': isRecurrent ? 1 : 0, // SQLite não tem booleano, usa 0 ou 1
      'recurrencyId': recurrencyId,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
      'isInInstallments': isInInstallments ? 1 : 0,
      'installmentCount': installmentCount,
    };
  }

  // Método para converter de Map (útil para Sqflite)
  factory Expense.fromMapForSqlite(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toString(), // O ID do Sqflite é int, mas o modelo usa String
      localId: map['id'] as int?,
      title: map['title'] as String,
      value: map['value'] as double,
      category: ExpenseCategory(
        name: map['category_name'] as String,
        icon: IconData(
          map['category_icon'] as int,
          fontFamily: 'MaterialIcons',
        ),
      ),
      note: map['note'] as String,
      date: DateTime.parse(map['date'] as String), // Converte String ISO para DateTime
      isRecurrent: (map['isRecurrent'] as int) == 1,
      recurrencyId: map['recurrencyId'] as int?,
      recurrencyType: map['recurrencyType'] as int?,
      recurrentIntervalDays: map['recurrentIntervalDays'] as int?,
      isInInstallments: (map['isInInstallments'] as int) == 1,
      installmentCount: map['installmentCount'] as int?,
    );
  }
  Map<String, dynamic> toMapForFirestore() {
    return {
      // O 'id' não é guardado aqui, ele é a chave do documento
      'title': title,
      'value': value,
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'note': note,
      'date': Timestamp.fromDate(date), // Converte DateTime para Timestamp
      'isRecurrent': isRecurrent,
      'recurrencyId': recurrencyId,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
      'isInInstallments': isInInstallments,
      'installmentCount': installmentCount,
    };
  }

  factory Expense.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return Expense(
      id: id, // Recebe o ID do documento
      title: map['title'],
      value: (map['value'] as num).toDouble(), // Converte 'num' para 'double'
      category: ExpenseCategory(
        name: map['category_name'],
        icon: IconData(
          map['category_icon'],
          fontFamily: 'MaterialIcons',
        ),
      ),
      note: map['note'],
      date: (map['date'] as Timestamp).toDate(), // Converte Timestamp para DateTime
      isRecurrent: map['isRecurrent'] ?? false,
      recurrencyId: map['recurrencyId'],
      recurrencyType: map['recurrencyType'],
      recurrentIntervalDays: map['recurrentIntervalDays'],
      isInInstallments: map['isInInstallments'] ?? false,
      installmentCount: map['installmentCount'],
    );
  }
  Expense copyWith({
    String? id,
    int? localId,
    String? title,
    double? value,
    ExpenseCategory? category,
    String? note,
    DateTime? date,
    bool? isRecurrent,
    int? recurrencyId,
    int? recurrencyType,
    int? recurrentIntervalDays,
    bool? isInInstallments,
    int? installmentCount,
  }) {
    return Expense(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      title: title ?? this.title,
      value: value ?? this.value,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      recurrencyId: recurrencyId ?? this.recurrencyId,
      recurrencyType: recurrencyType ?? this.recurrencyType,
      recurrentIntervalDays: recurrentIntervalDays ?? this.recurrentIntervalDays,
      isInInstallments: isInInstallments ?? this.isInInstallments,
      installmentCount: installmentCount ?? this.installmentCount,
    );
  }

}