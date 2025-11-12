import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp

class ProductOption {
  final String brand;
  final String storeName; // Simplificado de Store para String
  final double price;
  final String quantity; // Ex: "500g", "1un"
  final Timestamp purchaseDate; // Adicionado para rastrear a compra

  ProductOption({
    required this.brand,
    required this.storeName,
    required this.price,
    required this.quantity,
    required this.purchaseDate,
  });

  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'storeName': storeName,
      'price': price,
      'quantity': quantity,
      'purchaseDate': purchaseDate,
    };
  }

  // Método para converter de Map (útil para Firestore)
  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      brand: map['brand'] ?? 'N/A',
      storeName: map['storeName'] ?? 'Desconhecida',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 'N/A',
      // Garante que o timestamp seja lido corretamente
      purchaseDate: map['purchaseDate'] ?? Timestamp.now(),
    );
  }
  Map<String, dynamic> toMapForFirestore() {
    return {
      'brand': brand,
      'storeName': storeName,
      'price': price,
      'quantity': quantity,
      'purchaseDate': purchaseDate,
    };
  }

  factory ProductOption.fromMapFromFirestore(Map<String, dynamic> map) {
    return ProductOption(
      brand: map['brand'] ?? 'N/A',
      storeName: map['storeName'] ?? 'Desconhecida',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 'N/A',
      purchaseDate: map['purchaseDate'] as Timestamp,
    );
  }

  // Método para codificar uma lista de ProductOption para String JSON (útil para Sqflite)
  static String encode(List<ProductOption> options) {
    return json.encode(
        options.map<Map<String, dynamic>>((option) => option.toMap()).toList());
  }

  // Método para decodificar uma String JSON para uma lista de ProductOption (útil para Sqflite)
  static List<ProductOption> decode(String? optionsString) {
    if (optionsString == null || optionsString.isEmpty) {
      return [];
    }
    final List<dynamic> decodedList = json.decode(optionsString);
    return decodedList
        .map<ProductOption>((item) => ProductOption.fromMap(item))
        .toList();
  }
}
