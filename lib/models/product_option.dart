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
}
