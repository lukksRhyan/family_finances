import 'package:flutter/material.dart';

import 'expense_category.dart';
import 'receipt_category.dart';

class AppCategories {
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    ExpenseCategory(name: 'Moradia', icon: Icons.home),
    ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
  ];

  static const List<ReceiptCategory> receiptCategories = [
    ReceiptCategory(name: 'Salário', icon: Icons.monetization_on),
    ReceiptCategory(name: 'Presente', icon: Icons.card_giftcard),
    ReceiptCategory(name: 'Investimento', icon: Icons.trending_up),
    ReceiptCategory(name: 'Outros', icon: Icons.add_circle_outline),
  ];
}