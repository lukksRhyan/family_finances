import 'package:flutter/material.dart';

class ProductCategory {
  final String id; 
  final String name;
  final IconData icon;
  int? defaultPriority;

  ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.defaultPriority,
  });

  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

  // Método para converter de Map (útil para Firestore)
  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Desconhecida',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.label_outline.codePoint,
        fontFamily: map['iconFontFamily'] ?? Icons.label_outline.fontFamily,
      ),
      defaultPriority: map['defaultPriority'],
    );
  }
  // Método para converter para Map (útil para Sqflite)
  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

  // Método para converter de Map (útil para Sqflite)
  factory ProductCategory.fromMapForSqlite(Map<String, dynamic> map) {
    return ProductCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String?,
      ),
      defaultPriority: map['defaultPriority'] as int?,
    );
  }
  ProductCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? defaultPriority,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      defaultPriority: defaultPriority ?? this.defaultPriority,
    );
  }



  // Definindo algumas categorias padrão como constantes estáticas
  static final ProductCategory indefinida = ProductCategory(id: 'undefined', name: 'Indefinida', icon: Icons.label_outline);
  static final ProductCategory alimentacao = ProductCategory(id: 'food', name: 'Alimentação', icon: Icons.fastfood);
  static final ProductCategory casa = ProductCategory(id: 'home', name: 'Casa', icon: Icons.home);
  // Adicione outras categorias conforme necessário...

  // Método para buscar uma categoria padrão pelo nome (útil na importação)
  static ProductCategory getByName(String name) {
    // Implementar lógica para buscar em uma lista de categorias pré-definidas
    // Exemplo simplificado:
    if (name.toLowerCase().contains('comida') || name.toLowerCase().contains('alim')) {
      return alimentacao;
    }
    // ... outras lógicas ...
    return indefinida; // Retorna indefinida se não encontrar
  }
}
