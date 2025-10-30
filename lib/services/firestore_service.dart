import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/product_category.dart';
// Remove a importação do 'shopping_item.dart'
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart'; // Importa o novo modelo Product


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
  
  // *** INÍCIO DAS ALTERAÇÕES ***
  
  // Nova coleção para Produtos
  CollectionReference get _productsCollection =>
      _usersCollection.doc(uid).collection('products');
  
  // Nova coleção para Categorias de Produto
  CollectionReference get _productCategoriesCollection =>
      _usersCollection.doc(uid).collection('productCategories');

  // --- Métodos para Despesas (sem alteração) ---
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

  // --- Métodos para Receitas (sem alteração) ---
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

  // --- MÉTODOS PARA PRODUTOS (NOVOS/ATUALIZADOS) ---

  // Função auxiliar para buscar todas as categorias e mapeá-las por ID
  Future<Map<String, ProductCategory>> _getCategoryMap() async {
    final snapshot = await _productCategoriesCollection.get();
    final categories = snapshot.docs.map((doc) {
      return ProductCategory.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
    
    // Mapeia as categorias por ID
    Map<String, ProductCategory> categoryMap = {
      for (var cat in categories) cat.id!: cat
    };
    
    // Adiciona a categoria "indefinida" ao mapa para garantir que ela exista
    categoryMap[ProductCategory.indefinida.id!] = ProductCategory.indefinida;
    
    return categoryMap;
  }
  
  /// Adiciona um novo produto à coleção.
  Future<void> addProduct(Product product) =>
      _productsCollection.add(product.toMap());

  /// Atualiza um produto existente.
  Future<void> updateProduct(Product product) =>
      _productsCollection.doc(product.id).update(product.toMap());

  /// Apaga um produto pelo seu ID.
  Future<void> deleteProduct(String id) =>
      _productsCollection.doc(id).delete();

  /// Obtém um stream (fluxo em tempo real) dos produtos.
  Stream<List<Product>> getProductsStream() {
    // Ouve as mudanças nos produtos
    return _productsCollection.snapshots().asyncMap((productSnapshot) async {
      // A cada mudança nos produtos, busca o mapa atual de categorias
      final categoryMap = await _getCategoryMap();
      
      final products = productSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Converte os dados do produto
        return Product.fromMap(
          data,
          doc.id,
          categoryMap[data['categoryId']] ?? ProductCategory.indefinida,
        );
      }).toList();
      
      return products;
    });
  }

  // --- Métodos para Categorias de Produto ---
  
  /// Obtém um stream (fluxo em tempo real) das categorias
  Stream<List<ProductCategory>> getCategoriesStream() {
     return _productCategoriesCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Adiciona uma nova categoria de produto
  Future<void> addProductCategory(ProductCategory category) =>
      _productCategoriesCollection.add(category.toMap());
      
  // (Pode adicionar métodos update/delete para categorias se necessário)
}

