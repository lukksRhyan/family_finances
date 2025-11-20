// lib/models/nfce.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nfce_item_detail.dart';

class Nfce {
  final String? id;
  final String nfceKey;
  final String storeName;
  final double totalValue;
  final Timestamp date;
  final String taxInfo;
  final List<NfceItemDetail> items;

  Nfce({
    this.id,
    required this.nfceKey,
    required this.storeName,
    required this.totalValue,
    required this.date,
    required this.taxInfo,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'nfceKey': nfceKey,
      'storeName': storeName,
      'totalValue': totalValue,
      'date': date,
      'taxInfo': taxInfo,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory Nfce.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List? ?? [])
        .map((e) => NfceItemDetail.fromMap(e))
        .toList();

    return Nfce(
      id: id,
      nfceKey: map['nfceKey'],
      storeName: map['storeName'],
      totalValue: (map['totalValue'] as num).toDouble(),
      date: map['date'] ?? Timestamp.now(),
      taxInfo: map['taxInfo'],
      items: itemsList,
    );
  }
}
