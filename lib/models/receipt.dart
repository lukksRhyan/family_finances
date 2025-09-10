import 'package:flutter/material.dart';
import 'receipt_category.dart';

class Receipt {
  final int? id;
  final String title;
  final double value;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyId;
  final ReceiptCategory category;

  Receipt({
    this.id,
    required this.title,
    required this.value,
    required this.date,
    required this.isRecurrent,
    this.recurrencyId,
    required this.category,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      title: map['title'],
      value: map['value'],
      date: DateTime.parse(map['date']),
      isRecurrent: map['is_recurrent'] == 1,
      recurrencyId: map['recurrency_id'],
      category: ReceiptCategory(
        name: map['category_name'] ?? 'Outros',
        icon: IconData(
          int.tryParse(map['category_icon'] ?? '0xe360') ?? 0xe360, // Default to a generic icon if null
          fontFamily: 'MaterialIcons',
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'date': date.toIso8601String(),
      'category_name': category.name,
      'category_icon': category.icon.codePoint.toString(),
      'is_recurrent': isRecurrent ? 1 : 0,
      'recurrency_id': recurrencyId,
    };
  }
}