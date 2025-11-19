import 'package:flutter/material.dart';

import 'expense_category.dart';
import 'receipt_category.dart';

class AppCategories {
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(id: 'food', name: 'Comida', icon: Icons.fastfood),
    ExpenseCategory(id: 'home', name: 'Moradia', icon: Icons.home),
    ExpenseCategory(id: 'transport', name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory(id: 'leisure', name: 'Lazer', icon: Icons.sports_esports),
    ExpenseCategory(id: 'shopping', name: 'Compras', icon: Icons.shopping_cart),
    ExpenseCategory(id: 'health', name: 'Saúde', icon: Icons.local_hospital),
    ExpenseCategory(id: 'education', name: 'Educação', icon: Icons.school),
    ExpenseCategory(id: 'others', name: 'Outros', icon: Icons.category),
  ];

  static const List<ReceiptCategory> receiptCategories = [
    ReceiptCategory(id: 'salary', name: 'Salário', icon: Icons.monetization_on),
    ReceiptCategory(id: 'gift', name: 'Presente', icon: Icons.card_giftcard),
    ReceiptCategory(id: 'investment', name: 'Investimento', icon: Icons.trending_up),
    ReceiptCategory(id: 'others', name: 'Outros', icon: Icons.add_circle_outline),
  ];
}