import 'package:flutter/material.dart';

class ReceiptCategory {
  final String id; // ID é obrigatório
  final String name;
  final IconData icon;

  const ReceiptCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}