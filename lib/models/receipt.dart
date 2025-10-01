import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'receipt_category.dart';

class Receipt {
  final String? id;
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

  factory Receipt.fromMap(Map<String, dynamic> map, {String? id}) {
    return Receipt(
      id: id,
      title: map['title'],
      value: (map['value'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      isRecurrent: map['is_recurrent'] ?? false,
      recurrencyId: map['recurrency_id'],
      category: ReceiptCategory(
        name: map['category_name'] ?? 'Outros',
        icon: IconData(
          map['category_icon'] ?? 0xe360,
          fontFamily: 'MaterialIcons',
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'date': Timestamp.fromDate(date),
      'category_name': category.name,
      'category_icon': category.icon.codePoint,
      'is_recurrent': isRecurrent,
      'recurrency_id': recurrencyId,
    };
  }
}
