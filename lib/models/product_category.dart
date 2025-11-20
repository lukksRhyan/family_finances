// lib/models/product_category.dart
import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final IconData icon;
  final int? defaultPriority;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.defaultPriority,
  });

  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

  factory ProductCategory.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id,
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
      ),
      defaultPriority: map['defaultPriority'],
    );
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

  factory ProductCategory.fromMapForSqlite(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'],
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
      ),
      defaultPriority: map['defaultPriority'],
    );
  }

  static const indefinida = ProductCategory(
    id: 'undefined',
    name: 'Indefinida',
    icon: Icons.label_outline,
    defaultPriority: 3,
  );

  static const alimentacao = ProductCategory(
    id: 'food',
    name: 'Alimentação',
    icon: Icons.fastfood,
    defaultPriority: 1,
  );

  static const casa = ProductCategory(
    id: 'home',
    name: 'Casa',
    icon: Icons.home,
    defaultPriority: 2,
  );
}
