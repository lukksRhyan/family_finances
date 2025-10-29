import 'package:flutter/material.dart';

class ProductCategory {
  final String id; // Para referência, se gerido centralmente no futuro
  final String name;
  final IconData icon;
  int? defaultPriority; // Prioridade padrão associada à categoria (opcional)

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
