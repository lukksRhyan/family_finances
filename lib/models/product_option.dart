// lib/models/product_option.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductOption {
  final String brand;
  final String storeName;
  final double price;
  final String quantity;
  final Timestamp purchaseDate;

  ProductOption({
    required this.brand,
    required this.storeName,
    required this.price,
    required this.quantity,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'storeName': storeName,
      'price': price,
      'quantity': quantity,
      'purchaseDate': purchaseDate,
    };
  }

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      brand: map['brand'],
      storeName: map['storeName'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      purchaseDate: map['purchaseDate'] ?? Timestamp.now(),
    );
  }

  static String encode(List<ProductOption> list) =>
      jsonEncode(list.map((o) => o.toMap()).toList());

  static List<ProductOption> decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final raw = jsonDecode(jsonStr);
    return raw.map<ProductOption>((o) => ProductOption.fromMap(o)).toList();
  }
}
