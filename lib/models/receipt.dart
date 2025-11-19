import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String id;
  final String title;
  final double value;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyType;
  final int? localId;

  bool get isFuture => date.isAfter(DateTime.now());

  Receipt({
    required this.id,
    required this.title,
    required this.value,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.isRecurrent = false,
    this.recurrencyType,
    this.localId,
  });

  Receipt copyWith({
    String? id,
    String? title,
    double? value,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    bool? isRecurrent,
    int? recurrencyType,
    int? localId,
  }) {
    return Receipt(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      recurrencyType: recurrencyType ?? this.recurrencyType,
      localId: localId ?? this.localId,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'title': title,
      'value': value,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': Timestamp.fromDate(date),
      'isRecurrent': isRecurrent,
      'recurrencyType': recurrencyType,
    };
  }

  factory Receipt.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return Receipt(
      id: id,
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      categoryId: map['categoryId'] ?? 'outros',
      categoryName: map['categoryName'] ?? 'Outros',
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['isRecurrent'] ?? false,
      recurrencyType: map['recurrencyType'],
    );
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'recurrencyType': recurrencyType,
    };
  }

  factory Receipt.fromMapForSqlite(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      date: DateTime.parse(map['date']),
      isRecurrent: (map['isRecurrent'] ?? 0) == 1,
      recurrencyType: map['recurrencyType'],
      localId: map['localId'],
    );
  }
}
