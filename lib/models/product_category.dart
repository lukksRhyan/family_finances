import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final IconData icon;
  final int priority;

  ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.priority = 3,
  });

  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'priority': priority,
    };
  }

  factory ProductCategory.fromMapFromFirestore(
    Map<String, dynamic> map,
    String id,
  ) {
    return ProductCategory(
      id: id,
      name: map['name'],
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
      ),
      priority: map['priority'] ?? 3,
    );
  }

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'priority': priority,
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
      priority: map['priority'] ?? 3,
    );
  }

  static final ProductCategory indefinida = ProductCategory(
    id: 'undefined',
    name: 'Indefinida',
    icon: Icons.label_outline,
    priority: 3,
  );
}
