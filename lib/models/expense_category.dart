import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
