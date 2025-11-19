//lib/models/receipt_Category.dart
import 'package:flutter/material.dart';

class ReceiptCategory {
  final String name;
  final IconData icon;

  static const List<ReceiptCategory> basicCategories =[
    ReceiptCategory(name: 'Limpeza', icon: Icons.monetization_on),
    ReceiptCategory(name: 'Alimentação', icon: Icons.card_giftcard),
    ReceiptCategory(name: 'Lanches', icon: Icons.trending_up),
    ReceiptCategory(name: 'Outros', icon: Icons.add_circle_outline),
  ];
  static List<ReceiptCategory> allCategories(){
    List<ReceiptCategory> customCategories =[];
    return basicCategories+customCategories;
  }

  const ReceiptCategory({required this.name, required this.icon});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptCategory && other.name == name && other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(name, icon);

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
      name: map['name'] ?? 'Desconhecida',
      icon: IconData(
        map['icon'] ?? Icons.label_outline.codePoint,
        fontFamily: Icons.label_outline.fontFamily,
      ),
    );
  }
  
}