// lib/models/nfce_item_detail.dart
class NfceItemDetail {
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  NfceItemDetail({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory NfceItemDetail.fromMap(Map<String, dynamic> map) {
    return NfceItemDetail(
      name: map['name'],
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
    );
  }
}
