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
}