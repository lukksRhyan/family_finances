//lib/models/expense_category.dart
import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;

  const ExpenseCategory({required this.name, required this.icon});

  static List<ExpenseCategory> basicCategories = [
    ExpenseCategory(name: 'Alimentação', icon: Icons.fastfood),
    ExpenseCategory(name: 'Casa', icon: Icons.home),
    ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseCategory && other.name == name && other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(name, icon);

  static ExpenseCategory fromMapFromFirestore(Map<String, dynamic> map) {
    return ExpenseCategory(
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

  static ExpenseCategory fromMapForSqlite(Map<String, dynamic> map) {
    return ExpenseCategory(
      name: map['name'] ?? 'Desconhecida',
      icon: IconData(
        map['icon'] ?? Icons.label_outline.codePoint,
        fontFamily: Icons.label_outline.fontFamily,
      ),
    );
  }
  

  
}