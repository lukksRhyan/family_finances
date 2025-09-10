import 'package:flutter/material.dart';

class ReceiptCategory {
  final String name;
  final IconData icon;

  const ReceiptCategory({required this.name, required this.icon});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptCategory && other.name == name && other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(name, icon);
}