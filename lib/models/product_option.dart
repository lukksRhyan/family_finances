import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
      brand: map['brand'],
      storeName: map['storeName'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      purchaseDate: map['purchaseDate'],
    );
  }

  static String encode(List<ProductOption> list) {
    return json.encode(
      list.map((e) {
        return {
          'brand': e.brand,
          'storeName': e.storeName,
          'price': e.price,
          'quantity': e.quantity,
          'purchaseDate': e.purchaseDate.millisecondsSinceEpoch,
        };
      }).toList(),
    );
  }

  static List<ProductOption> decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final decoded = json.decode(jsonStr);
    return (decoded as List<dynamic>).map((e) {
      return ProductOption(
        brand: e['brand'],
        storeName: e['storeName'],
        price: (e['price'] as num).toDouble(),
        quantity: e['quantity'],
        purchaseDate: Timestamp.fromMillisecondsSinceEpoch(
          e['purchaseDate'],
        ),
      );
    }).toList();
  }
}
