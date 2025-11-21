// lib/models/expense.dart
import 'dart:convert'; // Adicionar import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'expense_category.dart';
import 'product.dart'; // Importar Product

class Expense {
  final String? id;
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
  final bool isShared;
  
  // NOVO CAMPO
  final List<Product> items;

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
    this.isShared = false,
    this.items = const [], // Padrão vazio
  });

  bool get isFuture => date.isAfter(DateTime.now());

  static Expense fromMap(Map<String, dynamic> map, {String? id}) {
    ExpenseCategory parsedCategory;
    try {
      if (map['category'] != null && map['category'] is Map) {
        parsedCategory = ExpenseCategory.fromMapFromFirestore(Map<String, dynamic>.from(map['category']));
      } else {
        parsedCategory = ExpenseCategory.defaults[0]; 
      }
    } catch (e) {
      parsedCategory = ExpenseCategory.defaults[0];
    }

    // --- LÓGICA PARA RECUPERAR ITENS ---
    List<Product> parsedItems = [];
    if (map['items'] != null) {
      final List rawItems = map['items'];
      parsedItems = rawItems.map((i) => Product.fromMapFromFirestore(i, '')).toList();
    } else if (map['itemsJson'] != null) {
       // Fallback para SQLite se usar JSON string
       // ... lógica de decode se necessário
    }
    // -----------------------------------

    return Expense(
      id: id,
      localId: null,
      title: map['title'] ?? '',
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : 0.0,
      category: parsedCategory,
      note: map['note'] ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      isRecurrent: map['is_recurrent'] ?? map['isRecurrent'] ?? false,
      recurrencyId: map['recurrency_id'] ?? map['recurrencyId'],
      recurrencyType: map['recurrency_type'] ?? map['recurrencyType'],
      recurrentIntervalDays: map['recurrent_interval_days'] ?? map['recurrentIntervalDays'],
      isInInstallments: map['is_in_installments'] ?? map['isInInstallments'] ?? false,
      installmentCount: map['installment_count'] ?? map['installmentCount'],
      isShared: map['isShared'] ?? false,
      items: parsedItems, // Atribui a lista
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'category': category.toMapForFirestore(),
      'note': note,
      'date': Timestamp.fromDate(date),
      'is_recurrent': isRecurrent,
      'recurrency_id': recurrencyId,
      'recurrency_type': recurrencyType,
      'recurrent_interval_days': recurrentIntervalDays,
      'is_in_installments': isInInstallments,
      'installment_count': installmentCount,
      'isShared': isShared,
      // Salva os itens como lista de mapas no Firestore
      'items': items.map((p) => p.toMapForFirestore()).toList(),
    };
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'category': category.toMapForSqlite(),
      'note': note,
      'date': date.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'recurrencyId': recurrencyId,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
      'isInInstallments': isInInstallments ? 1 : 0,
      'installmentCount': installmentCount,
      'isShared': isShared ? 1 : 0,
      'sharedFromUid': null,
      // SQLite não aceita Arrays, convertemos para JSON String se tiver coluna
      // Se não tiver coluna criada no database_helper, isso será ignorado pelo insert
      'itemsJson': jsonEncode(items.map((p) => p.toMapForSqlite()).toList()),
    };
  }

  factory Expense.fromMapForSqlite(Map<String, dynamic> map) {
    final localId = map['localId'] is int
        ? map['localId'] as int
        : (map['localId'] != null ? int.tryParse(map['localId'].toString()) : null);

    // Recuperar itens do JSON string
    List<Product> parsedItems = [];
    if (map['itemsJson'] != null) {
       try {
         final List raw = jsonDecode(map['itemsJson']);
         parsedItems = raw.map((x) => Product.fromMapForSqlite(x)).toList();
       } catch (_) {}
    }

    return Expense(
      id: map['id']?.toString(),
      localId: localId,
      title: map['title']?.toString() ?? '',
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : double.tryParse(map['value']?.toString() ?? '') ?? 0.0,
      category: ExpenseCategory.fromMapForSqlite(map['category'] ?? map), 
      note: map['note']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      isRecurrent: (map['isRecurrent'] ?? 0) == 1,
      recurrencyId: map['recurrencyId'] is int ? map['recurrencyId'] as int : (map['recurrencyId'] != null ? int.tryParse(map['recurrencyId'].toString()) : null),
      recurrencyType: map['recurrencyType'] is int ? map['recurrencyType'] as int : (map['recurrencyType'] != null ? int.tryParse(map['recurrencyType'].toString()) : null),
      recurrentIntervalDays: map['recurrentIntervalDays'] is int ? map['recurrentIntervalDays'] as int : (map['recurrentIntervalDays'] != null ? int.tryParse(map['recurrentIntervalDays'].toString()) : null),
      isInInstallments: (map['isInInstallments'] ?? 0) == 1,
      installmentCount: map['installmentCount'] is int ? map['installmentCount'] as int : (map['installmentCount'] != null ? int.tryParse(map['installmentCount'].toString()) : null),
      isShared: (map['isShared'] ?? 0) == 1,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMapForFirestore() => toMap();

  factory Expense.fromMapFromFirestore(Map<String, dynamic> map, String id) => fromMap(map, id: id);

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
    bool? isShared,
    List<Product>? items, // Novo parâmetro
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
      isShared: isShared ?? this.isShared,
      items: items ?? this.items,
    );
  }
}