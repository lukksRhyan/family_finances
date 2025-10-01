import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/receipt.dart';

class FirestoreService {
  final String uid;

  FirestoreService({required this.uid});

  // Referência para a coleção de despesas do utilizador
  CollectionReference get _expensesCollection =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('expenses');

  // Referência para a coleção de receitas do utilizador
  CollectionReference get _receiptsCollection =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('receipts');

  // --- Funções para Despesas ---

  Future<void> addExpense(Expense expense) {
    return _expensesCollection.add(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) {
    return _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) {
    return _expensesCollection.doc(expenseId).delete();
  }

  // Obtém um stream de despesas para atualizações em tempo real
  Stream<List<Expense>> getExpensesStream() {
    return _expensesCollection.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense.fromMap(data, id: doc.id); // Passa o ID do documento
      }).toList();
    });
  }

  // --- Funções para Receitas ---

  Future<void> addReceipt(Receipt receipt) {
    return _receiptsCollection.add(receipt.toMap());
  }
   Future<void> updateReceipt(Receipt receipt) {
    return _receiptsCollection.doc(receipt.id).update(receipt.toMap());
  }

  Future<void> deleteReceipt(String receiptId) {
    return _receiptsCollection.doc(receiptId).delete();
  }

  // Obtém um stream de receitas
  Stream<List<Receipt>> getReceiptsStream() {
    return _receiptsCollection.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Receipt.fromMap(data, id: doc.id); // Passa o ID do documento
      }).toList();
    });
  }
}