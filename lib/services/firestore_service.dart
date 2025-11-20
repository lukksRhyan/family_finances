// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class FirestoreService {
  final String uid;
  FirestoreService({required this.uid});

  CollectionReference get _usersCollection => FirebaseFirestore.instance.collection('users');

  // withConverter helpers
  CollectionReference<Map<String, dynamic>> _subcol(String name) =>
      _usersCollection.doc(uid).collection(name).withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (map, _) => map,
      );

  CollectionReference get _expensesCollection => _usersCollection.doc(uid).collection('expenses');
  CollectionReference get _receiptsCollection => _usersCollection.doc(uid).collection('receipts');
  CollectionReference get _productsCollection => _usersCollection.doc(uid).collection('products');
  CollectionReference get _productCategoriesCollection => _usersCollection.doc(uid).collection('productCategories');

  // Expenses
  Future<void> addExpense(Expense expense, {String? sharedCollectionId}) =>
      _expensesCollection.add(expense.toMapForFirestore());

  Future<void> updateExpense(Expense expense) =>
      _expensesCollection.doc(expense.id).update(expense.toMapForFirestore());

  Future<void> deleteExpense(String id) => _expensesCollection.doc(id).delete();

  Stream<List<Expense>> getExpensesStream() {
    print(_expensesCollection);
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final map = doc.data() as Map<String, dynamic>;
              // Normalize date if Timestamp
              if (map['date'] is Timestamp) {
                map['date'] = (map['date'] as Timestamp).toDate();
              }
              map['categoryId'] = map['categoryId'] ?? 'indefinida';
              map['categoryName'] = map['categoryName'] ?? 'Outros';
              return Expense.fromMapFromFirestore(map, doc.id);
            }).toList());
  }

  // Receipts
  Future<void> addReceipt(Receipt receipt) =>
      _receiptsCollection.add(receipt.toMapForFirestore());

  Future<void> updateReceipt(Receipt receipt) =>
      _receiptsCollection.doc(receipt.id).update(receipt.toMapForFirestore());

  Future<void> deleteReceipt(String id) => _receiptsCollection.doc(id).delete();

  Stream<List<Receipt>> getReceiptsStream() {
    print(_receiptsCollection);
    return _receiptsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final map = doc.data() as Map<String, dynamic>;
              if (map['date'] is Timestamp) map['date'] = (map['date'] as Timestamp).toDate();
              map['categoryId'] = map['categoryId'] ?? 'outros';
              map['categoryName'] = map['categoryName'] ?? 'Outros';
              return Receipt.fromMapFromFirestore(map, doc.id);
            }).toList());
  }

  // Products & categories
  Future<Map<String, ProductCategory>> _getCategoryMap() async {
    final snapshot = await _productCategoriesCollection.get();
    final categories = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // ensure id is set
      return ProductCategory.fromMapFromFirestore(data, doc.id);
    }).toList();

    final map = {for (var c in categories) c.id: c};
    map[ProductCategory.indefinida.id] = ProductCategory.indefinida;
    return map;
  }

  Future<void> addProduct(Product product) => _productsCollection.add(product.toMapForFirestore());
  Future<void> updateProduct(Product product) => _productsCollection.doc(product.id).update(product.toMapForFirestore());
  Future<void> deleteProduct(String id) => _productsCollection.doc(id).delete();

  Stream<List<Product>> getProductsStream() {
    return _productsCollection.snapshots().asyncMap((productSnapshot) async {
      final categoryMap = await _getCategoryMap();
      final products = productSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final cat = categoryMap[data['categoryId']] ?? ProductCategory.indefinida;
        return Product.fromMapFromFirestore(data, doc.id);
      }).toList();
      return products;
    });
  }

  Stream<List<ProductCategory>> getCategoriesStream() {
    return _productCategoriesCollection
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ProductCategory.fromMapFromFirestore(data, doc.id);
            }).toList());
  }

  Future<void> addProductCategory(ProductCategory category) =>
      _productCategoriesCollection.add(category.toMapForFirestore());
}
