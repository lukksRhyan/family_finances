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
  static List<ProductCategory> standardCategories = [
    ProductCategory(id: 'food', name: 'Comida', icon: Icons.fastfood),
    ProductCategory(id: 'home', name: 'Moradia', icon: Icons.home),
    ProductCategory(id: 'shopping', name: 'Compras', icon: Icons.shopping_cart),
    ProductCategory(id: 'education', name: 'Educação', icon: Icons.school),
    ProductCategory(id: 'entertainment', name: 'Entretenimento', icon: Icons.movie),
        ProductCategory(id: 'hygiene', name: 'Higiene', icon: Icons.clean_hands),
    ProductCategory(id: 'pets', name: 'Pets', icon: Icons.pets),
    ProductCategory(id: 'transport', name: 'Transporte', icon: Icons.directions_car),
    ProductCategory(id: 'health', name: 'Saúde', icon: Icons.local_hospital),
    ProductCategory(id: 'leisure', name: 'Lazer', icon: Icons.sports_esports),
    ProductCategory(id: 'clothes', name: 'Vestuário', icon: Icons.checkroom),
    ProductCategory(id: 'others', name: 'Outros', icon: Icons.more_horiz),
  ];
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
