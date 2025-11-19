import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class FirestoreService {
  final String uid;
  FirestoreService({required this.uid});

  CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference get _expensesCollection =>
      _usersCollection.doc(uid).collection('expenses');

  CollectionReference get _receiptsCollection =>
      _usersCollection.doc(uid).collection('receipts');

  CollectionReference get _productsCollection =>
      _usersCollection.doc(uid).collection('products');

  CollectionReference get _productCategoriesCollection =>
      _usersCollection.doc(uid).collection('productCategories');

  Future<void> addExpense(Expense expense) {
    return _expensesCollection.add(expense.toMapForFirestore());
  }

  Future<void> updateExpense(Expense expense) {
    return _expensesCollection.doc(expense.id).update(expense.toMapForFirestore());
  }

  Future<void> deleteExpense(String id) {
    return _expensesCollection.doc(id).delete();
  }

  Stream<List<Expense>> getExpensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final map = doc.data() as Map<String, dynamic>;
        if (map['date'] is Timestamp) {
          map['date'] = (map['date'] as Timestamp).toDate();
        }
        return Expense.fromMapFromFirestore(map, doc.id);
      }).toList();
    });
  }

  Future<void> addReceipt(Receipt receipt) {
    return _receiptsCollection.add(receipt.toMapForFirestore());
  }

  Future<void> updateReceipt(Receipt receipt) {
    return _receiptsCollection.doc(receipt.id).update(receipt.toMapForFirestore());
  }

  Future<void> deleteReceipt(String id) {
    return _receiptsCollection.doc(id).delete();
  }

  Stream<List<Receipt>> getReceiptsStream() {
    return _receiptsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final map = doc.data() as Map<String, dynamic>;
        if (map['date'] is Timestamp) {
          map['date'] = (map['date'] as Timestamp).toDate();
        }
        return Receipt.fromMapFromFirestore(map, doc.id);
      }).toList();
    });
  }

  Future<Map<String, ProductCategory>> _getCategoryMap() async {
    final snapshot = await _productCategoriesCollection.get();
    final categories = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ProductCategory.fromMapFromFirestore(data, doc.id);
    }).toList();

    final map = {for (var c in categories) c.id: c};
    map[ProductCategory.indefinida.id] = ProductCategory.indefinida;
    return map;
  }

  Future<void> addProduct(Product product) {
    return _productsCollection.add(product.toMapForFirestore());
  }

  Future<void> updateProduct(Product product) {
    return _productsCollection.doc(product.id).update(product.toMapForFirestore());
  }

  Future<void> deleteProduct(String id) {
    return _productsCollection.doc(id).delete();
  }

  Stream<List<Product>> getProductsStream() {
    return _productsCollection.snapshots().asyncMap((snapshot) async {
      final categoryMap = await _getCategoryMap();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final cat = categoryMap[data['categoryId']] ?? ProductCategory.indefinida;
        return Product.fromMapFromFirestore(data, doc.id, cat);
      }).toList();
    });
  }

  Stream<List<ProductCategory>> getCategoriesStream() {
    return _productCategoriesCollection.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductCategory.fromMapFromFirestore(data, doc.id);
      }).toList();
    });
  }

  Future<void> addProductCategory(ProductCategory category) {
    return _productCategoriesCollection.add(category.toMapForFirestore());
  }
}
