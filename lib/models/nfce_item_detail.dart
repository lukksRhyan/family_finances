// Representa um item específico lido de uma nota fiscal

class NfceItemDetail {
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  // Outros campos relevantes da nota, se necessário (e.g., código NCM)

  NfceItemDetail({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

   // Método para converter para Map (útil para Firestore, se for salvar)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

   // Método para converter de Map (útil para Firestore)
  factory NfceItemDetail.fromMap(Map<String, dynamic> map) {
    return NfceItemDetail(
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return '$quantity x $name @ R\$${unitPrice.toStringAsFixed(2)} = R\$${totalPrice.toStringAsFixed(2)}';
  }
}
