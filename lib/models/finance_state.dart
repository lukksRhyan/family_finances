import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Serviços
import '../services/firestore_service.dart';
import '../services/gemini_service.dart'; // Importa o serviço da IA
// Modelos de Dados
import 'expense.dart';
import 'receipt.dart';
import 'product.dart'; // Usa o novo modelo Product
import 'product_category.dart'; // Importa o modelo ProductCategory
import 'product_option.dart'; // Importa o modelo ProductOption
import 'nfce.dart'; // Importa o modelo Nfce (renomeado)
import 'expense_category.dart'; // Para a despesa "Compras"

class FinanceState with ChangeNotifier {
  FirestoreService? _firestoreService;
  late GeminiService _geminiService; // Serviço da IA
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _receiptsSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _productCategoriesSubscription; // Para as categorias da IA

  List<Expense> _expenses = [];
  List<Receipt> _receipts = [];
  List<Product> _products = [];
  List<ProductCategory> _productCategories = []; // Lista de categorias de produtos
  bool _isLoading = true;

  // --- Getters Públicos ---
  List<Expense> get expenses => _expenses;
  List<Receipt> get receipts => _receipts;
  List<Product> get shoppingListProducts => _products;
  List<ProductCategory> get productCategories => _productCategories;
  bool get isLoading => _isLoading;

  // Mantém a lista estática de categorias de despesa (usada no add_transaction_screen)
  // TODO: Migrar isto para o Firestore também pode ser um próximo passo
  final List<ExpenseCategory> _expenseCategories = [
    const ExpenseCategory(name: 'Compras', icon: Icons.shopping_cart),
    const ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    const ExpenseCategory(name: 'Moradia', icon: Icons.home),
    const ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    const ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
    const ExpenseCategory(name: 'Outros', icon: Icons.category),
  ];
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  // --- Inicialização ---
  FinanceState() {
    _geminiService = GeminiService(); // Inicializa o serviço da IA
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initializeData(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void _initializeData(String uid) {
    _firestoreService = FirestoreService(uid: uid);
    _isLoading = true;
    notifyListeners(); // Notifica que o carregamento começou

    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _productsSubscription?.cancel();
    _productCategoriesSubscription?.cancel();

    int streamsToLoad = 4; // Agora esperamos 4 streams
    int streamsLoaded = 0;

    // Função para verificar se todos os streams foram carregados
    void checkLoading() {
      streamsLoaded++;
      // Só termina o loading quando todos os 4 streams tiverem sido carregados
      if (streamsLoaded == streamsToLoad && _isLoading) {
        _isLoading = false;
        notifyListeners();
      } else if (!_isLoading) {
         // Se o loading já terminou, apenas notifica as atualizações de dados
         notifyListeners();
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
      // Adiciona "Indefinida" no início da lista para ser usada como padrão
      _productCategories = [ProductCategory.indefinida, ...data];
      checkLoading();
    }, onError: (e) { print("Erro no stream de categorias de produtos: $e"); checkLoading(); });
  }


  void _clearData() {
    _firestoreService = null;
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _productsSubscription?.cancel();
    _productCategoriesSubscription?.cancel();
    _expenses = [];
    _receipts = [];
    _products = [];
    _productCategories = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _productsSubscription?.cancel();
    _productCategoriesSubscription?.cancel();
    super.dispose();
  }

  // --- Funções para Produtos (usando FirestoreService) ---

  Future<void> addProduct(Product product) async {
    await _firestoreService?.addProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    await _firestoreService?.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _firestoreService?.deleteProduct(productId);
  }

  Future<void> toggleProductChecked(Product product, bool value) async {
    // Cria uma cópia atualizada do produto
    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      options: product.options,
      isChecked: value, // Atualiza o estado
      priority: product.priority,
    );
    await _firestoreService?.updateProduct(updatedProduct);
  }
  
  /// Adiciona uma nova categoria de produto ao Firestore
  Future<void> addProductCategory(ProductCategory category) async {
    await _firestoreService?.addProductCategory(category);
  }

  // --- Função para Processar Itens da NFC-e (com IA) ---
  Future<void> processNfceItems(Nfce nota) async {
     if (_firestoreService == null) throw Exception("Serviço Firestore não inicializado.");
     if (_productCategories.isEmpty) throw Exception("Categorias de produtos não carregadas.");

      print('Processando ${nota.items.length} itens da NFC-e da ${nota.storeName}');

      // 1. Preparar dados para a IA
      final itemNames = nota.items.map((e) => e.name).toList();
      // Envia apenas os nomes das categorias, excluindo "Indefinida" da sugestão
      final categoryNames = _productCategories
          .where((c) => c.id != ProductCategory.indefinida.id)
          .map((e) => e.name)
          .toList();

      // 2. Chamar a IA para classificar os produtos
      List<ClassifiedProduct> classifiedItems = [];
      try {
        classifiedItems = await _geminiService.classifyProducts(itemNames, categoryNames);
      } catch (e) {
        print("Erro ao classificar com IA: $e. A classificar como 'Indefinida'.");
        // Se a IA falhar, cria uma lista manual com prioridade e categoria padrão
        classifiedItems = itemNames.map((name) => ClassifiedProduct(
          productName: name,
          categoryName: ProductCategory.indefinida.name,
          priority: 3, // Prioridade neutra
        )).toList();
      }
      
      if (classifiedItems.length != nota.items.length) {
         print("Aviso: Resposta da IA com ${classifiedItems.length} itens, esperado ${nota.items.length}. A importação pode estar incompleta.");
         // Continua mesmo assim, processando os itens que vieram
      }

      // 3. Processar e salvar os produtos
      for (int i = 0; i < classifiedItems.length; i++) {
         if (i >= nota.items.length) break; // Segurança extra
         
         final classifiedItem = classifiedItems[i];
         final nfceItem = nota.items[i];

         // Encontra o objeto ProductCategory
         final category = _productCategories.firstWhere(
           (c) => c.name.toLowerCase() == classifiedItem.categoryName.toLowerCase(),
           orElse: () => ProductCategory.indefinida, // Padrão se a IA inventar uma categoria
         );
         
         final normalizedItemName = classifiedItem.productName.trim().toLowerCase();
         // Busca na lista local de produtos
         Product? existingProduct = _products.firstWhere(
               (p) => p.name.trim().toLowerCase() == normalizedItemName,
                orElse: () => Product.notFound(), // Método auxiliar para retornar um produto "inválido"
            );

          final newOption = ProductOption(
            brand: 'Genérico', // IA pode refinar isto no futuro
            storeName: nota.storeName,
            price: nfceItem.unitPrice,
            // Formata a quantidade para remover zeros desnecessários se for inteiro
            quantity: nfceItem.quantity.toStringAsFixed(nfceItem.quantity.truncateToDouble() == nfceItem.quantity ? 0 : 3),
            purchaseDate: nota.date,
          );

          if (existingProduct.id != null) {
              // Produto existe: Adiciona a opção e atualiza
              print('Produto "${nfceItem.name}" encontrado. Adicionando opção.');
              existingProduct.options.add(newOption);
              existingProduct.options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
              
              // Atualiza a prioridade para a mais essencial (menor número)
              existingProduct.priority = (existingProduct.priority! < classifiedItem.priority) 
                                         ? existingProduct.priority 
                                         : classifiedItem.priority;
              
              // Atualiza a categoria se a atual for "Indefinida"
              if (existingProduct.category.id == ProductCategory.indefinida.id) {
                existingProduct.category = category;
              }
              
              await updateProduct(existingProduct);
          } else {
              // Produto não existe: Cria um novo
              print('Produto "${nfceItem.name}" NÃO encontrado. Criando novo produto.');
              final newProduct = Product(
                  name: nfceItem.name.trim(), // Usa o nome original da nota
                  category: category,
                  options: [newOption],
                  isChecked: false,
                  priority: classifiedItem.priority,
              );
              await addProduct(newProduct);
          }
      }

      // 4. Cria uma única Despesa resumida para a compra total
      final obs = "Importação NFC-e: ${nota.storeName}\n"
                  "${nota.taxInfo}\n\n"
                  "Itens:\n" +
                  nota.items.map((e) => "- ${e.name.trim()} (${e.quantity}x ${e.unitPrice.toStringAsFixed(2)})").join("\n");

      // Tenta encontrar a categoria "Compras", senão usa a primeira que encontrar
      final category = _expenseCategories.firstWhere(
        (c) => c.name.toLowerCase() == 'compras',
        orElse: () => _expenseCategories.first, // Pega a primeira categoria de despesa como fallback
      );

      final summaryExpense = Expense(
        title: "Compras - ${nota.storeName}",
        value: nota.totalValue,
        category: category,
        note: obs,
        date: nota.date.toDate(), // Converte Timestamp para DateTime
        isRecurrent: false,
        isInInstallments: false,
      );
      await addExpense(summaryExpense);

      print('Processamento da NFC-e e classificação da IA concluídos.');
  }

  // --- Funções de Despesas e Receitas (sem alterações) ---
  Future<void> addExpense(Expense expense) async => await _firestoreService?.addExpense(expense);
  Future<void> updateExpense(Expense expense) async => await _firestoreService?.updateExpense(expense);
  Future<void> deleteExpense(String id) async => await _firestoreService?.deleteExpense(id);
  Future<void> addReceipt(Receipt receipt) async => await _firestoreService?.addReceipt(receipt);
  Future<void> updateReceipt(Receipt receipt) async => await _firestoreService?.updateReceipt(receipt);
  Future<void> deleteReceipt(String id) async => await _firestoreService?.deleteReceipt(id);

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

