import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Serviços
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../database_helper.dart'; // Importa o DB local
// Modelos de Dados
import 'expense.dart';
import 'receipt.dart';
import 'product.dart';
import 'product_category.dart';
import 'product_option.dart';
import 'nfce_item_detail.dart';
import 'nfce.dart';
import 'expense_category.dart';

class FinanceState with ChangeNotifier {
  // Serviços
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  late GeminiService _geminiService;
  
  // Controlo de Estado
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _receiptsSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _productCategoriesSubscription;
  String? _uid;
  bool _isLoading = true;

  // Listas de Dados
  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Product> _products = [];
  List<ProductCategory> _productCategories = [];
  // Categorias de Despesa (estáticas por agora)
  final List<ExpenseCategory> _expenseCategories = [
    const ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart),
    const ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    const ExpenseCategory(name: 'Moradia', icon: Icons.home),
    const ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    const ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
    const ExpenseCategory(name: 'Outros', icon: Icons.category),
  ];
  
  // --- Getters Públicos ---
  bool get isLoggedIn => _uid != null;
  List<Expense> get expenses => _expenses;
  List<Receipt> get receipts => _receipts;
  List<Product> get shoppingListProducts => _products;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  // --- Inicialização ---
  FinanceState() {
    _geminiService = GeminiService();
    // Ouve as mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChanged(user);
    });
    // Verifica o estado inicial (pode já estar logado ou não)
    _handleAuthStateChanged(FirebaseAuth.instance.currentUser);
  }
  
  /// Trata a mudança de utilizador, decidindo se carrega dados locais ou da nuvem.
  void _handleAuthStateChanged(User? user) {
     // Só reinicializa se o estado de login *realmente* mudou
     if (user != null && _uid != user.uid) {
      // Utilizador Logado (ou mudou de utilizador)
      _uid = user.uid;
      _initializeCloudData(user.uid);
    } else if (user == null && _uid != null) {
      // Utilizador Deslogou (vai para o modo local)
      _uid = null;
      _initializeLocalData();
    } else if (user == null && _uid == null) {
      // Utilizador continua deslogado (ex: abriu a app sem login)
      // Evita recarregar desnecessariamente se já estiver em modo local
      if (_products.isEmpty && _expenses.isEmpty && _receipts.isEmpty) {
         _initializeLocalData();
      }
    }
    // Se user != null && _uid == user.uid, não faz nada (já está inicializado)
  }


  /// Carrega todos os dados do banco de dados SQFlite local
  Future<void> _initializeLocalData() async {
    print("Inicializando em MODO LOCAL (Sqflite)");
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    // Limpa subscrições antigas da nuvem
    await _clearCloudSubscriptions();
    _firestoreService = null;

    // Carrega dados do Sqflite
    try {
      _expenses = await _databaseHelper.getAllExpenses();
      _receipts = await _databaseHelper.getAllReceipts();
      _productCategories = await _databaseHelper.getAllProductCategories();
      _products = await _databaseHelper.getAllProducts();
    } catch (e) {
      print("Erro ao carregar dados locais: $e");
      // Reseta as listas em caso de erro
      _expenses = [];
      _receipts = [];
      _productCategories = [];
      _products = [];
    }

    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Inicializa os streams para ouvir o Firestore
  void _initializeCloudData(String uid) {
    print("Inicializando em MODO NUVEM (Firestore) para $uid");
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _firestoreService = FirestoreService(uid: uid);
    _clearCloudSubscriptions(); // Garante que não há streams duplicados

    int streamsToLoad = 4;
    int streamsLoaded = 0;

    void checkLoading() {
      streamsLoaded++;
      if (streamsLoaded == streamsToLoad && _isLoading) {
        _isLoading = false;
        notifyListeners();
      } else if (!_isLoading) {
        notifyListeners(); // Apenas notifica a atualização dos dados
      }
    }

    _expensesSubscription = _firestoreService!.getExpensesStream().listen((data) {
      _expenses = data; checkLoading();
    }, onError: (e) { print("Erro no stream de despesas: $e"); checkLoading(); });

    _receiptsSubscription = _firestoreService!.getReceiptsStream().listen((data) {
      _receipts = data; checkLoading();
    }, onError: (e) { print("Erro no stream de receitas: $e"); checkLoading(); });

    _productsSubscription = _firestoreService!.getProductsStream().listen((data) {
      _products = data; checkLoading();
    }, onError: (e) { print("Erro no stream de produtos: $e"); checkLoading(); });

    _productCategoriesSubscription = _firestoreService!.getCategoriesStream().listen((data) {
      _productCategories = [ProductCategory.indefinida, ...data];
      checkLoading();
    }, onError: (e) { print("Erro no stream de categorias: $e"); checkLoading(); });
  }

  /// Limpa todos os dados e streams (chamado no logout)
  void _clearData() {
    _uid = null;
    _firestoreService = null;
    _clearCloudSubscriptions();
    _expenses = [];
    _receipts = [];
    _products = [];
    _productCategories = [];
    _isLoading = false; // Pára o loading se estava a carregar
    notifyListeners();
  }

  /// Método auxiliar para cancelar todos os streams
  Future<void> _clearCloudSubscriptions() async {
    await _expensesSubscription?.cancel();
    await _receiptsSubscription?.cancel();
    await _productsSubscription?.cancel();
    await _productCategoriesSubscription?.cancel();
    _expensesSubscription = null;
    _receiptsSubscription = null;
    _productsSubscription = null;
    _productCategoriesSubscription = null;
  }
  
  /// Sincroniza os dados locais para o Firebase (chamado no login)
  Future<void> syncLocalDataToFirebase(String newUid) async {
    print("Iniciando sincronização de dados locais para a nuvem...");
    if (_firestoreService == null || _firestoreService!.uid != newUid) {
      _firestoreService = FirestoreService(uid: newUid);
    }

    // 1. Carrega todos os dados locais
    final localExpenses = await _databaseHelper.getAllExpenses();
    final localReceipts = await _databaseHelper.getAllReceipts();
    final localCategories = await _databaseHelper.getAllProductCategories();
    final localProducts = await _databaseHelper.getAllProducts();

    // 2. Envia para o Firestore
    // Categorias de Produto
    for (final category in localCategories) {
      // Evita re-enviar categorias padrão que já podem existir
      if (!category.id.startsWith('default_') && !category.id.startsWith('undefined')) {
         await _firestoreService!.addProductCategory(category);
      }
    }

    // Produtos
    for (final product in localProducts) {
      // A lógica `addProduct` no FirestoreService já lida com a `categoryId`
      await _firestoreService!.addProduct(product);
    }
    
    // Despesas e Receitas
    for (final expense in localExpenses) {
      await _firestoreService!.addExpense(expense);
    }
    for (final receipt in localReceipts) {
      await _firestoreService!.addReceipt(receipt);
    }

    // 3. Limpa os dados locais após a sincronização
    await _databaseHelper.deleteAllLocalData();
    print("Sincronização concluída. Dados locais apagados.");
    
    // 4. Os streams do _initializeCloudData (que serão acionados pela mudança de auth)
    // vão agora carregar os dados da nuvem.
  }

  /// Recarrega todos os dados do Sqflite (usado após updates locais)
  Future<void> _loadAllDataFromSqlite() async {
      _expenses = await _databaseHelper.getAllExpenses();
      _receipts = await _databaseHelper.getAllReceipts();
      _products = await _databaseHelper.getAllProducts();
      // Categorias geralmente não mudam no modo local, mas podemos recarregar por segurança
      _productCategories = await _databaseHelper.getAllProductCategories();
      notifyListeners();
  }


  @override
  void dispose() {
    _clearCloudSubscriptions();
    super.dispose();
  }

  // --- MÉTODOS CRUD MULTIPLEXADOS ---

  Future<void> addExpense(Expense expense) async {
    if (isLoggedIn) {
      await _firestoreService?.addExpense(expense);
      // Stream notifica
    } else {
      final newExpense = await _databaseHelper.createExpense(expense);
      _expenses.insert(0, newExpense.copyWith(localId: newExpense.localId)); // Garante que o ID local está na cópia
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    if (isLoggedIn) {
      await _firestoreService?.updateExpense(expense);
      // Stream notifica
    } else {
      await _databaseHelper.updateExpense(expense);
      await _loadAllDataFromSqlite(); // Recarrega e notifica
    }
  }

  Future<void> deleteExpense(String id) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteExpense(id);
      // Stream notifica
    } else {
      // No modo local, o ID é um int
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteExpense(localId);
      _expenses.removeWhere((e) => e.localId == localId); // Atualiza lista local
      notifyListeners();
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    if (isLoggedIn) {
      await _firestoreService?.addReceipt(receipt);
    } else {
       final newReceipt = await _databaseHelper.createReceipt(receipt);
      _receipts.insert(0, newReceipt.copyWith(localId: newReceipt.localId));
      notifyListeners();
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    if (isLoggedIn) {
      await _firestoreService?.updateReceipt(receipt);
    } else {
      await _databaseHelper.updateReceipt(receipt);
      await _loadAllDataFromSqlite();
    }
  }

  Future<void> deleteReceipt(String id) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteReceipt(id);
    } else {
      final localId = int.tryParse(id);
      if (localId == null) return;
      await _databaseHelper.deleteReceipt(localId);
      _receipts.removeWhere((r) => r.localId == localId);
      notifyListeners();
    }
  }
  
  Future<void> addProduct(Product product) async {
    if (isLoggedIn) {
      await _firestoreService?.addProduct(product);
    } else {
       final newProduct = await _databaseHelper.createProduct(product);
      _products.add(newProduct.copyWith(localId: newProduct.localId));
      _products.sort((a, b) => a.nameLower.compareTo(b.nameLower));
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    if (isLoggedIn) {
      await _firestoreService?.updateProduct(product);
    } else {
      await _databaseHelper.updateProduct(product);
      // Recarrega do DB local para ter a lista ordenada e atualizada
      _products = await _databaseHelper.getAllProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (isLoggedIn) {
      await _firestoreService?.deleteProduct(productId);
    } else {
      final localId = int.tryParse(productId);
      if (localId == null) return;
      await _databaseHelper.deleteProduct(localId);
      _products.removeWhere((p) => p.localId == localId);
      notifyListeners();
    }
  }

  Future<void> toggleProductChecked(Product product, bool value) async {
    final updatedProduct = product.copyWith(isChecked: value);
    if (isLoggedIn) {
      // O stream do Firestore tratará da atualização da UI
      await _firestoreService?.updateProduct(updatedProduct);
    } else {
      // Atualiza localmente
      await _databaseHelper.updateProduct(updatedProduct);
      final index = _products.indexWhere((p) => p.localId == updatedProduct.localId);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
    }
  }
  
  Future<void> addProductCategory(ProductCategory category) async {
     if (isLoggedIn) {
      await _firestoreService?.addProductCategory(category);
    } else {
      await _databaseHelper.createProductCategory(category);
      _productCategories.add(category);
      notifyListeners();
    }
  }

  // --- Função para Processar Itens da NFC-e (com IA) ---
  Future<void> processNfceItems(Nfce nota) async {
     // A IA e o processamento da nota só funcionam se o utilizador estiver logado
     if (!isLoggedIn || _firestoreService == null) {
       throw Exception("Você precisa estar logado para usar a importação de NFC-e.");
     }
     if (_productCategories.isEmpty) {
       // Tenta carregar as categorias se estiverem vazias
       _productCategories = await _firestoreService!.getCategoriesStream().first;
       if (_productCategories.isEmpty) {
          throw Exception("Categorias de produtos não carregadas. Tente novamente.");
       }
     }

      print('Processando ${nota.items.length} itens da NFC-e da ${nota.storeName}');

      final itemNames = nota.items.map((e) => e.name).toList();
      final categoryNames = _productCategories
          .where((c) => c.id != ProductCategory.indefinida.id)
          .map((e) => e.name)
          .toList();

      List<ClassifiedProduct> classifiedItems = [];
      try {
        classifiedItems = await _geminiService.classifyProducts(itemNames, categoryNames);
      } catch (e) {
        print("Erro ao classificar com IA: $e. A classificar como 'Indefinida'.");
        classifiedItems = itemNames.map((name) => ClassifiedProduct(
          productName: name,
          categoryName: ProductCategory.indefinida.name,
          priority: 3,
        )).toList();
      }
      
      if (classifiedItems.length != nota.items.length) {
         print("Aviso: Resposta da IA com ${classifiedItems.length} itens, esperado ${nota.items.length}.");
      }

      for (int i = 0; i < classifiedItems.length; i++) {
         if (i >= nota.items.length) break;
         
         final classifiedItem = classifiedItems[i];
         final nfceItem = nota.items[i];

         final category = _productCategories.firstWhere(
           (c) => c.name.toLowerCase() == classifiedItem.categoryName.toLowerCase(),
           orElse: () => ProductCategory.indefinida,
         );
         
         final normalizedItemName = classifiedItem.productName.trim().toLowerCase();
         Product? existingProduct = _products.firstWhere(
               (p) => p.name.trim().toLowerCase() == normalizedItemName,
                orElse: () => Product.notFound(),
            );

          final newOption = ProductOption(
            brand: 'Genérico',
            storeName: nota.storeName,
            price: nfceItem.unitPrice,
            quantity: nfceItem.quantity.toStringAsFixed(nfceItem.quantity.truncateToDouble() == nfceItem.quantity ? 0 : 3),
            purchaseDate: nota.date, // nfce.dart foi atualizado para usar DateTime
          );

          if (existingProduct.id != null) {
              existingProduct.options.add(newOption);
              existingProduct.options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
              existingProduct.priority = (existingProduct.priority != null && existingProduct.priority! < classifiedItem.priority)
                                         ? existingProduct.priority 
                                         : classifiedItem.priority;
              if (existingProduct.category.id == ProductCategory.indefinida.id) {
                existingProduct.category = category;
              }
              await updateProduct(existingProduct); // Usa o método multiplexado
          } else {
              final newProduct = Product(
                  name: nfceItem.name.trim(),
                  category: category,
                  options: [newOption],
                  isChecked: false,
                  priority: classifiedItem.priority,
              );
              await addProduct(newProduct); // Usa o método multiplexado
          }
      }

      // 4. Cria uma única Despesa resumida para a compra total
      final obs = "Importação NFC-e: ${nota.storeName}\n"
                  "${nota.taxInfo}\n\n"
                  "Itens:\n" +
                  nota.items.map((e) => "- ${e.name.trim()} (${e.quantity}x ${e.unitPrice.toStringAsFixed(2)})").join("\n");

      final category = _expenseCategories.firstWhere(
        (c) => c.name.toLowerCase() == 'compras',
        orElse: () => _expenseCategories.first,
      );

      final summaryExpense = Expense(
        title: "Compras - ${nota.storeName}",
        value: nota.totalValue,
        category: category,
        note: obs,
        date: nota.date.toDate(), // nfce.dart foi atualizado para usar DateTime
        isRecurrent: false,
        isInInstallments: false,
      );
      await addExpense(summaryExpense); // Usa o método multiplexado
      print('Processamento da NFC-e e classificação da IA concluídos.');
  }

  // --- Getters (sem alterações) ---
  double get totalReceitas => receipts.fold(0.0, (sum, item) => sum + item.value);
  double get totalDespesas => expenses.fold(0.0, (sum, item) => sum + item.value);
  double get totalReceitasAtuais => receipts.where((r) => !r.isFuture).fold(0.0, (sum, item) => sum + item.value);
  double get totalDespesasAtuais => expenses.where((e) => !e.isFuture).fold(0.0, (sum, item) => sum + item.value);
  double get saldoAtual => totalReceitasAtuais - totalDespesasAtuais;

  // --- Método para forçar notificação (útil para RefreshIndicator) ---
  void forceNotify() {
    notifyListeners();
  }
}