import 'package:family_finances/models/expense.dart';
import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;

  const ExpenseCategory({
    required this.name,
    required this.icon,
  });
  static List<ExpenseCategory> standardCategories = [
    ExpenseCategory( name: 'Comida', icon: Icons.fastfood),
    ExpenseCategory( name: 'Moradia', icon: Icons.home),
    ExpenseCategory( name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory( name: 'Lazer', icon: Icons.sports_esports),
    ExpenseCategory( name: 'Compras', icon: Icons.shopping_cart),
    ExpenseCategory( name: 'Saúde', icon: Icons.local_hospital),
    ExpenseCategory( name: 'Educação', icon: Icons.school),
    ExpenseCategory( name: 'Outros', icon: Icons.category),
  ];
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseCategory && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  Map<String,dynamic> toMapForFirestore() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  factory ExpenseCategory.fromMapFromFirestore(Map<String, dynamic> map) {
    return ExpenseCategory(
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
  factory ExpenseCategory.fromMapForSqlite(Map<String, dynamic> map) {
    return ExpenseCategory(
      name: map['name'],
      icon: map['icon'],
    );
}
}
