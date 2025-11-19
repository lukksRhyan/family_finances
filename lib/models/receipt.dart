// lib/models/receipt.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'receipt_category.dart';

class Receipt {
  final String? id;
  final int? localId;
  final String title;
  final double value;
  final DateTime date;
  final bool isRecurrent;
  final int? recurrencyType;
  final bool isShared;
  final String? sharedFromUid;
  final ReceiptCategory category;

  Receipt({
    this.id,
    this.localId,
    required this.title,
    required this.value,
    required this.date,
    this.isRecurrent = false,
    this.recurrencyType,
    this.isShared = false,
    this.sharedFromUid,
    required this.category,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  Receipt copyWith({
    String? id,
    int? localId,
    String? title,
    double? value,
    DateTime? date,
    bool? isRecurrent,
    int? recurrencyType,
    bool? isShared,
    String? sharedFromUid,
    ReceiptCategory? category,
  }) {
    return Receipt(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      title: title ?? this.title,
      value: value ?? this.value,
      date: date ?? this.date,
      isRecurrent: isRecurrent ?? this.isRecurrent,
      recurrencyType: recurrencyType ?? this.recurrencyType,
      isShared: isShared ?? this.isShared,
      sharedFromUid: sharedFromUid ?? this.sharedFromUid,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'title': title,
      'value': value,
      // Store the Firestore-friendly Timestamp
      'date': Timestamp.fromDate(date),
      'isRecurrent': isRecurrent,
      'recurrencyType': recurrencyType,
      'isShared': isShared,
      'sharedFromUid': sharedFromUid,
      'categoryId': category.id,
      'categoryName': category.name,
    };
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'date': date.toIso8601String(),
      'isRecurrent': isRecurrent ? 1 : 0,
      'recurrencyType': recurrencyType,
      'isShared': isShared ? 1 : 0,
      'sharedFromUid': sharedFromUid,
      'categoryId': category.id,
      'categoryName': category.name,
    };
  }

  factory Receipt.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now();
    }

    return Receipt(
      id: id,
      localId: null,
      title: map['title'] ?? '',
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : double.tryParse(map['value']?.toString() ?? '') ?? 0.0,
      date: parsedDate,
      isRecurrent: map['isRecurrent'] ?? false,
      recurrencyType: map['recurrencyType'] as int?,
      isShared: map['isShared'] ?? false,
      sharedFromUid: map['sharedFromUid']?.toString(),
      category: ReceiptCategory(
        name: map['categoryName'] ?? 'Outros',
        icon: Icons.attach_money,
        id: map['categoryId']?.toString() ?? 'outros',
      ),
    );
  }

  factory Receipt.fromMapForSqlite(Map<String, dynamic> map) {
    final localId = map['localId'] is int
        ? map['localId'] as int
        : (map['localId'] != null ? int.tryParse(map['localId'].toString()) : null);

    return Receipt(
      id: map['id']?.toString(),
      localId: localId,
      title: map['title'] ?? '',
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : double.tryParse(map['value']?.toString() ?? '') ?? 0.0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      isRecurrent: (map['isRecurrent'] ?? 0) == 1,
      recurrencyType: map['recurrencyType'] is int ? map['recurrencyType'] as int : (map['recurrencyType'] != null ? int.tryParse(map['recurrencyType'].toString()) : null),
      isShared: (map['isShared'] ?? 0) == 1,
      sharedFromUid: map['sharedFromUid']?.toString(),
      category: ReceiptCategory(
        name: map['categoryName'] ?? 'Outros',
        icon: Icons.attach_money,
        id: map['categoryId']?.toString() ?? 'outros',
      ),
    );
  }
}
