// lib/models/transaction.dart
import 'package:flutter/material.dart';

abstract class TransactionModel {
  String? get id;
  String get title;
  double get value;
  DateTime get date;
  bool get isRecurrent;

  String get categoryName;
  IconData get categoryIcon;

  bool get isExpense;

  Map<String, dynamic> toMapForFirestore();
  Map<String, dynamic> toMapForSqlite();
}
