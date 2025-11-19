import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/receipt_category.dart';

class Receipt {
  final String id;
  final String title;
  final double value;
  final ReceiptCategory category;
  final DateTime date;
  final bool isRecurrent;
  final bool isShared;
  final int? recurrencyType;
  final int? localId;

  bool get isFuture => date.isAfter(DateTime.now());

  Receipt({
    required this.id,
    required this.title,
    required this.value,
    required this.category,
    required this.date,
    this.isRecurrent = false,
    this.isShared = false,
    this.recurrencyType,
    this.localId,
  });

  Receipt copyWith({
    String? id,
    String? title,
    double? value,
    ReceiptCategory? category,
    DateTime? date,
    bool? isRecurrent,
    bool? isShared,
    int? recurrencyType,
    int? localId,
  }) {
    return Receipt(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      category: category ?? this.category,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      isShared: isShared ?? this.isShared,
      recurrencyType: recurrencyType ?? this.recurrencyType,
      localId: localId ?? this.localId,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'title': title,
      'value': value,
      'category': category.toMapForFirestore(),
      'date': Timestamp.fromDate(date),
      'isRecurrent': isRecurrent,
      'isShared': isShared,
      'recurrencyType': recurrencyType,
    };
  }

  factory Receipt.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return Receipt(
      id: id,
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      category: ReceiptCategory.fromMapFromFirestore(map['category']),
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['isRecurrent'] ?? false,
      isShared: map['isShared'] ?? false,
      recurrencyType: map['recurrencyType'],
    );
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'category': category.toMapForSqlite(),
      'date': date.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'isShared': isShared ? 1 : 0,
      'recurrencyType': recurrencyType,
    };
  }

  factory Receipt.fromMapForSqlite(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      category: ReceiptCategory.fromMapForSqlite(map['category']),
      date: DateTime.parse(map['date']),
      isRecurrent: (map['isRecurrent'] ?? 0) == 1,
      isShared: (map['isShared'] ?? 0) == 1,
      recurrencyType: map['recurrencyType'],
      localId: map['localId'],
    );
  }
}
