import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/shopping_item.dart';

class FirestoreService {
  final String uid;
  FirestoreService({required this.uid});

  // Coleção principal do utilizador
  CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  // Sub-coleções para cada tipo de dado
  CollectionReference get _expensesCollection =>
      _usersCollection.doc(uid).collection('expenses');
  CollectionReference get _receiptsCollection =>
      _usersCollection.doc(uid).collection('receipts');
  CollectionReference get _shoppingListCollection =>
      _usersCollection.doc(uid).collection('shoppingList');

  // --- Métodos para Despesas ---
  Future<void> addExpense(Expense expense) =>
      _expensesCollection.add(expense.toMap());
  Future<void> updateExpense(Expense expense) =>
      _expensesCollection.doc(expense.id).update(expense.toMap());
  Future<void> deleteExpense(String id) => _expensesCollection.doc(id).delete();
  Stream<List<Expense>> getExpensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
            .toList());
  }

  // --- Métodos para Receitas ---
  Future<void> addReceipt(Receipt receipt) =>
      _receiptsCollection.add(receipt.toMap());
  Future<void> updateReceipt(Receipt receipt) =>
      _receiptsCollection.doc(receipt.id).update(receipt.toMap());
  Future<void> deleteReceipt(String id) => _receiptsCollection.doc(id).delete();
  Stream<List<Receipt>> getReceiptsStream() {
    return _receiptsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Receipt.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
            .toList());
  }

  // --- MÉTODOS PARA A LISTA DE COMPRAS ---

  /// Adiciona um novo item à lista de compras.
  Future<void> addShoppingItem(ShoppingItem item) =>
      _shoppingListCollection.add(item.toMap());

  /// Atualiza um item existente na lista de compras.
  Future<void> updateShoppingItem(ShoppingItem item) =>
      _shoppingListCollection.doc(item.id).update(item.toMap());

  /// Apaga um item da lista de compras pelo seu ID.
  Future<void> deleteShoppingItem(String id) =>
      _shoppingListCollection.doc(id).delete();

  /// Obtém um stream (fluxo em tempo real) da lista de compras.
  Stream<List<ShoppingItem>> getShoppingListStream() {
    return _shoppingListCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingItem.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
            .toList());
  }
}

