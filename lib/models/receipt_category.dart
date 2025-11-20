// lib/models/receipt_category.dart
import 'package:flutter/material.dart';

class ReceiptCategory {
  final String name;
  final IconData icon;

  const ReceiptCategory({required this.name, required this.icon});

  static const defaults = [
    ReceiptCategory(name: 'Salário', icon: Icons.monetization_on),
    ReceiptCategory(name: 'Presente', icon: Icons.card_giftcard),
    ReceiptCategory(name: 'Investimento', icon: Icons.trending_up),
    ReceiptCategory(name: 'Outros', icon: Icons.add_circle_outline),
  ];
  
  static ReceiptCategory defaultCategory = defaults[0];


  static List<ReceiptCategory> allCategories() => [...defaults];

  static ReceiptCategory fromMapFromFirestore(Map<String, dynamic> map) {
    return ReceiptCategory(
      name: map['name'] ?? 'Desconhecida',
      icon: IconData(
        map['icon'] ?? Icons.label_outline.codePoint,
        fontFamily: Icons.label_outline.fontFamily,
      ),
    );
  }

  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'icon': icon.codePoint,
    };
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'name': name,
      'icon': icon.codePoint,
    };
  }

  static ReceiptCategory fromMapForSqlite(Map<String, dynamic> map) {
    return ReceiptCategory(
      name: map['name'],
      icon: IconData(
        map['icon'],
        fontFamily: Icons.label_outline.fontFamily,
      ),
    );
  }
}
