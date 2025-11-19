import 'package:flutter/material.dart';

class ReceiptCategory {
  final String name;
  final IconData icon;

  const ReceiptCategory({
    required this.name,
    required this.icon,
  });
  static List<ReceiptCategory> standardCategories = [
    ReceiptCategory( name: 'Salário', icon: Icons.monetization_on),
    ReceiptCategory(name: 'Presente', icon: Icons.card_giftcard),
    ReceiptCategory( name: 'Investimento', icon: Icons.trending_up),
    ReceiptCategory(name: 'Outros', icon: Icons.add_circle_outline),
  ];
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptCategory && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  Map<String,dynamic> toMapForFirestore() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  factory ReceiptCategory.fromMapFromFirestore(Map<String, dynamic> map) {
    return ReceiptCategory(
      name: map['name'],
      icon: map['icon'],
    );
  }
  Map<String, dynamic> toMapForSqlite() {
    return {
      'name': name,
      'icon': icon,
    };
  }
  factory ReceiptCategory.fromMapForSqlite(Map<String, dynamic> map) {
    return ReceiptCategory(
      name: map['name'],
      icon: map['icon'],
    );
}
}
