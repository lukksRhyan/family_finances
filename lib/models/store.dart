import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  String id;
  String name;
  GeoPoint location;

  Store({required this.id, required this.name, required this.location});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
    };

  }
}