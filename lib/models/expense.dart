import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/expense_category.dart';

class Expense {
  final String id;
  final String title;
  final double value;
  final ExpenseCategory category;
  final String? note;
  final DateTime date;
  final bool isRecurrent;
  final bool isShared;
  final bool isInInstallments;
  final int installmentCount;
  final int? recurrencyType;
  final int? recurrentIntervalDays;
  final int? localId;

  bool get isFuture => date.isAfter(DateTime.now());

  Expense({
    required this.id,
    required this.title,
    required this.value,
    required this.category,
    this.note,
    required this.date,
    this.isRecurrent = false,
    this.isShared = false,
    this.isInInstallments = false,
    this.installmentCount = 1,
    this.recurrencyType,
    this.recurrentIntervalDays,
    this.localId,
  });

  Expense copyWith({
    String? id,
    String? title,
    double? value,
    ExpenseCategory? category,
    String? note,
    DateTime? date,
    bool? isRecurrent,
    bool? isInInstallments,
    int? installmentCount,
    int? recurrencyType,
    int? recurrentIntervalDays,
    int? localId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      isInInstallments: isInInstallments ?? this.isInInstallments,
      installmentCount: installmentCount ?? this.installmentCount,
      recurrencyType: recurrencyType ?? this.recurrencyType,
      recurrentIntervalDays:
          recurrentIntervalDays ?? this.recurrentIntervalDays,
      localId: localId ?? this.localId,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'title': title,
      'value': value,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'isRecurrent': isRecurrent,
      'isShared': isShared,
      'isInInstallments': isInInstallments,
      'installmentCount': installmentCount,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
    };
  }

  factory Expense.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      category: ExpenseCategory.fromMapFromFirestore(map['category']),
      note: map['note'],
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['isRecurrent'] ?? false,
      isShared: map['isShared'] ?? false,
      isInInstallments: map['isInInstallments'] ?? false,
      installmentCount: map['installmentCount'] ?? 1,
      recurrencyType: map['recurrencyType'],
      recurrentIntervalDays: map['recurrentIntervalDays'],
    );
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
      'isShared': isShared ? 1 : 0,
      'isInInstallments': isInInstallments ? 1 : 0,
      'installmentCount': installmentCount,
      'recurrencyType': recurrencyType,
      'recurrentIntervalDays': recurrentIntervalDays,
    };
  }

  factory Expense.fromMapForSqlite(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      category: ExpenseCategory.fromMapForSqlite(map['category']),
      note: map['note'],
      date: DateTime.parse(map['date']),
      isRecurrent: (map['isRecurrent'] ?? 0) == 1,
      isShared: (map['isShared'] ?? 0) == 1,
      isInInstallments: (map['isInInstallments'] ?? 0) == 1,
      installmentCount: map['installmentCount'] ?? 1,
      recurrencyType: map['recurrencyType'],
      recurrentIntervalDays: map['recurrentIntervalDays'],
      localId: map['localId'],
    );
  }
}
