import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/partnership.dart';
import 'package:family_finances/models/product_category.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart';
// Importa o novo modelo

// Constantes para o caminho da coleção pública compartilhada
const String PUBLIC_TRANSACTIONS_PATH = 'shared_transactions';
const String PARTNERSHIPS_COLLECTION = 'partnerships';
const String PARTNERSHIP_INVITES_COLLECTION = 'partnership_invites';

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
  
  // Nova coleção para Produtos
  CollectionReference get _productsCollection =>
      _usersCollection.doc(uid).collection('products');
  
  // Nova coleção para Categorias de Produto
  CollectionReference get _productCategoriesCollection =>
      _usersCollection.doc(uid).collection('productCategories');
      
  // Coleção de Parcerias na raiz (pública)
  CollectionReference get partnershipsCollection =>
      FirebaseFirestore.instance.collection(PARTNERSHIPS_COLLECTION);
  
  // Coleção de Convites de Parceria (pública)
  CollectionReference get partnershipInvitesCollection =>
      FirebaseFirestore.instance.collection(PARTNERSHIP_INVITES_COLLECTION);
      
  // --- Métodos de Parceria ---

  /// Envia um convite de parceria para outro usuário (UID, que pode ser simulado por email no teste).
  Future<void> sendPartnershipInvite(String receiverUidOrEmail) async {
    // Usaremos o UID (ou email no teste) do recebedor como ID de convite temporário.
    final inviteId = Partnership.createId(uid, receiverUidOrEmail); 

    final invite = PartnershipInvite(
      id: inviteId,
      senderId: uid,
      receiverId: receiverUidOrEmail, // Aqui, para simplificar, o receiverId é o UID/Email
      sentAt: Timestamp.now(),
    );

    // Salva o convite
    await partnershipInvitesCollection.doc(inviteId).set(invite.toMap());
  }
  
  /// Busca a parceria atual do usuário.
  /// Retorna a Parceria ou null se não houver.
  // NOTE: A busca real por parceria é feita no FinanceState usando Rx.combineLatest2.
  Stream<Partnership?> getPartnershipStream() {
    // Retorna um stream base para um dos lados da busca.
    return partnershipsCollection
        .where('user1Id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return Partnership.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
          }
          return null;
        });
  }

  /// Cria ou aceita uma parceria.
  Future<Partnership> establishPartnership(String partnerUid) async {
    final partnershipId = Partnership.createId(uid, partnerUid);
    
    // O ID da coleção compartilhada será o ID da Partnership
    final sharedCollectionId = partnershipId; 

    final partnership = Partnership(
      id: partnershipId,
      user1Id: Partnership.createId(uid, partnerUid) == uid ? uid : partnerUid,
      user2Id: Partnership.createId(uid, partnerUid) == uid ? partnerUid : uid,
      sharedCollectionId: sharedCollectionId,
    );

    await partnershipsCollection.doc(partnershipId).set(partnership.toMap());
    
    // Remove o convite após estabelecer a parceria (se existir)
    try {
        final inviteId = Partnership.createId(uid, partnerUid);
        await partnershipInvitesCollection.doc(inviteId).delete();
    } catch (_) {
        // Ignora se o convite não existir
    }

    return partnership;
  }
  
  /// Termina a parceria.
  Future<void> removePartnership(String partnershipId) async {
    // Deleta o documento da parceria
    await partnershipsCollection.doc(partnershipId).delete();
    // NOTA: As transações conjuntas permanecem na shared_transactions
  }

  // --- Funções Auxiliares para Coleções Compartilhadas ---
  
  // Rota para a coleção compartilhada: artifacts/{appId}/public/data/shared_transactions/{sharedCollectionId}/...
  CollectionReference _getSharedCollectionRef(String sharedCollectionId, String transactionType) {
     return FirebaseFirestore.instance
      .collection('artifacts')
      .doc('FamilyFinances') // Usando nome fixo para simulação
      .collection('public')
      .doc('data')
      .collection(PUBLIC_TRANSACTIONS_PATH)
      .doc(sharedCollectionId)
      .collection(transactionType); // 'expenses' ou 'receipts'
  }

  CollectionReference getSharedExpensesCollection(String sharedCollectionId) {
    return _getSharedCollectionRef(sharedCollectionId, 'expenses');
  }

  CollectionReference getSharedReceiptsCollection(String sharedCollectionId) {
    return _getSharedCollectionRef(sharedCollectionId, 'receipts');
  }

  // --- MÉTODOS CRUD (Privados e Compartilhados) ---

  Future<void> addExpense(Expense expense, {String? sharedCollectionId}) {
    if (expense.isShared && sharedCollectionId != null) {
      return getSharedExpensesCollection(sharedCollectionId).add(expense.toMap());
    } else {
      return _expensesCollection.add(expense.toMap());
    }
  }

  Future<void> updateExpense(Expense expense, {String? sharedCollectionId}) {
    if (expense.isShared && sharedCollectionId != null && expense.id != null) {
      return getSharedExpensesCollection(sharedCollectionId).doc(expense.id).update(expense.toMap());
    } else if (expense.id != null) {
      return _expensesCollection.doc(expense.id).update(expense.toMap());
    }
    return Future.value();
  }

  Future<void> deleteExpense(String id, {String? sharedCollectionId, bool isShared = false}) {
     if (isShared && sharedCollectionId != null) {
       return getSharedExpensesCollection(sharedCollectionId).doc(id).delete();
     }
     return _expensesCollection.doc(id).delete();
  }

  Future<void> addReceipt(Receipt receipt, {String? sharedCollectionId}) {
    if (receipt.isShared && sharedCollectionId != null) {
      return getSharedReceiptsCollection(sharedCollectionId).add(receipt.toMap());
    } else {
      return _receiptsCollection.add(receipt.toMap());
    }
  }

  Future<void> updateReceipt(Receipt receipt, {String? sharedCollectionId}) {
    if (receipt.isShared && sharedCollectionId != null && receipt.id != null) {
      return getSharedReceiptsCollection(sharedCollectionId).doc(receipt.id).update(receipt.toMap());
    } else if (receipt.id != null) {
      return _receiptsCollection.doc(receipt.id).update(receipt.toMap());
    }
    return Future.value();
  }

  Future<void> deleteReceipt(String id, {String? sharedCollectionId, bool isShared = false}) {
    if (isShared && sharedCollectionId != null) {
      return getSharedReceiptsCollection(sharedCollectionId).doc(id).delete();
    }
    return _receiptsCollection.doc(id).delete();
  }
  
  // --- MÉTODOS DE STREAM PRIVADOS (utilizados pelo FinanceState) ---
  
  Stream<List<Expense>> getPrivateExpensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<Receipt>> getPrivateReceiptsStream() {
    return _receiptsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Receipt.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // --- MÉTODOS PRODUTOS E CATEGORIAS (mantidos) ---

  Future<Map<String, ProductCategory>> _getCategoryMap() async {
    final snapshot = await _productCategoriesCollection.get();
    final categories = snapshot.docs.map((doc) {
      return ProductCategory.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
    
    Map<String, ProductCategory> categoryMap = {
      for (var cat in categories) cat.id: cat
    };
    
    categoryMap[ProductCategory.indefinida.id] = ProductCategory.indefinida;
    
    return categoryMap;
  }
  
  Future<void> addProduct(Product product) =>
      _productsCollection.add(product.toMap());

  Future<void> updateProduct(Product product) =>
      _productsCollection.doc(product.id).update(product.toMap());

  Future<void> deleteProduct(String id) =>
      _productsCollection.doc(id).delete();

  Stream<List<Product>> getProductsStream() {
    return _productsCollection.snapshots().asyncMap((productSnapshot) async {
      final categoryMap = await _getCategoryMap();
      
      final products = productSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromMapFromFirestore(
          data,
          doc.id,
          categoryMap[data['categoryId']] ?? ProductCategory.indefinida,
        );
      }).toList();
      
      return products;
    });
  }

  Stream<List<ProductCategory>> getCategoriesStream() {
     return _productCategoriesCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromMapFromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addProductCategory(ProductCategory category) =>
      _productCategoriesCollection.doc(category.id).set(category.toMap());
}