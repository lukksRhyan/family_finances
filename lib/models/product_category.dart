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

  // --- CONVERSORES DO FIRESTORE (MÉTODOS NOVOS) ---

  /// Converte este objeto para um Map para o Firestore (sem ID, pois é a chave do doc)
  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

  /// Converte de um Documento do Firestore para um objeto ProductCategory
  factory ProductCategory.fromMapFromFirestore(Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id, // Recebe o ID do documento separadamente
      name: map['name'] ?? 'Desconhecida',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.label_outline.codePoint,
        fontFamily: map['iconFontFamily'] ?? Icons.label_outline.fontFamily,
      ),
      defaultPriority: map['defaultPriority'],
    );
  }

  // --- Conversores do Sqflite (Mantidos) ---

  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': id, // No SQLite, o ID faz parte do mapa
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'defaultPriority': defaultPriority,
    };
  }

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

  // --- Métodos Auxiliares ---

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

  static final ProductCategory indefinida = ProductCategory(id: 'undefined', name: 'Indefinida', icon: Icons.label_outline, defaultPriority: 3);
  static final ProductCategory alimentacao = ProductCategory(id: 'food', name: 'Alimentação', icon: Icons.fastfood, defaultPriority: 1);
  static final ProductCategory casa = ProductCategory(id: 'home', name: 'Casa', icon: Icons.home, defaultPriority: 2);

  static ProductCategory getByName(String name) {
    if (name.toLowerCase().contains('comida') || name.toLowerCase().contains('alim')) {
      return alimentacao;
    }
    return indefinida;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'ProductCategory{id: $id, name: $name}';
  }

  static fromMap(Map<String, dynamic> data) {}

  Object? toMap() {}
}