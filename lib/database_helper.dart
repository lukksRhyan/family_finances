import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Para codificar/decodificar a lista de opções
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('family_finances_v2.db'); // v2 para nova schema
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB, onConfigure: _onConfigure);
  }

  // Ativa chaves estrangeiras
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idTypeInt = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const idTypeText = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intTypeNull = 'INTEGER';

    // Tabela de Categorias de Produto (nova)
    await db.execute('''
    CREATE TABLE product_categories (
      id $idTypeText,
      name $textType,
      iconCodePoint $intType,
      iconFontFamily $textTypeNull,
      defaultPriority $intTypeNull
    )
    ''');
    
    // Insere as categorias padrão
    await _insertDefaultCategories(db);

    // Tabela de Produtos (nova)
    await db.execute('''
    CREATE TABLE products (
      id $idTypeInt,
      name $textType,
      nameLower $textType,
      categoryId $textType NOT NULL,
      priority $intTypeNull,
      options $textTypeNull,
      isChecked $intType NOT NULL,
      FOREIGN KEY (categoryId) REFERENCES product_categories (id)
    )
    ''');

    // Tabela de Despesas (atualizada)
    await db.execute('''
    CREATE TABLE expenses (
      id $idTypeInt,
      title $textType,
      value $realType,
      category_name $textType,
      category_icon $intType,
      note $textTypeNull,
      date $textType,
      isRecurrent $intType NOT NULL,
      recurrencyId $intTypeNull,
      recurrencyType $intTypeNull,
      recurrentIntervalDays $intTypeNull,
      isInInstallments $intType NOT NULL,
      installmentCount $intTypeNull
    )
    ''');

    // Tabela de Receitas (atualizada)
    await db.execute('''
    CREATE TABLE receipts (
      id $idTypeInt,
      title $textType,
      value $realType,
      date $textType,
      category_name $textType,
      category_icon $intType,
      isRecurrent $intType NOT NULL,
      recurrencyId $intTypeNull
    )
    ''');
  }

  // Insere categorias padrão no DB local
  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      ProductCategory.indefinida,
      ProductCategory.alimentacao,
      ProductCategory.casa,
      // Adicione outras categorias estáticas que você queira
    ];
    
    Batch batch = db.batch();
    for (var category in categories) {
      batch.insert('product_categories', category.toMapForSqlite(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  // --- Métodos CRUD para Categorias de Produto ---
  Future<int> createProductCategory(ProductCategory category) async {
    final db = await instance.database;
    return await db.insert('product_categories', category.toMapForSqlite());
  }

  Future<List<ProductCategory>> getAllProductCategories() async {
    final db = await instance.database;
    final result = await db.query('product_categories');
    return result.map((json) => ProductCategory.fromMapForSqlite(json)).toList();
  }
  
  // (update/delete para categorias se necessário)

  // --- Métodos CRUD para Produtos ---
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert('products', product.toMapForSqlite());
    return product.copyWith(id: id.toString());
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMapForSqlite(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    
    // Busca todas as categorias primeiro
    final categoriesList = await getAllProductCategories();
    final categoryMap = {for (var cat in categoriesList) cat.id: cat};
    // Garante que a indefinida está no mapa
    categoryMap[ProductCategory.indefinida.id] = ProductCategory.indefinida;

    final result = await db.query('products', orderBy: 'nameLower ASC');
    
    return result.map((json) {
      // Encontra a categoria correspondente ou usa "indefinida"
      final category = categoryMap[json['categoryId'] as String] ?? ProductCategory.indefinida;
      return Product.fromMapForSqlite(json, category);
    }).toList();
  }

  // --- Métodos CRUD para Despesas (Atualizados para usar int ID) ---
  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMapForSqlite());
    return expense.copyWith(id: id.toString());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toMapForSqlite(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMapForSqlite(json)).toList();
  }

  // --- Métodos CRUD para Receitas (Atualizados para usar int ID) ---
  Future<Receipt> createReceipt(Receipt receipt) async {
    final db = await instance.database;
    final id = await db.insert('receipts', receipt.toMapForSqlite());
    return receipt.copyWith(id: id.toString());
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await instance.database;
    return await db.update(
      'receipts',
      receipt.toMapForSqlite(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await instance.database;
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await instance.database;
    final result = await db.query('receipts', orderBy: 'date DESC');
    return result.map((json) => Receipt.fromMapForSqlite(json)).toList();
  }
  
  // --- Método para Sincronização ---
  
  /// Apaga todos os dados de transações (usado antes de um sync)
  Future<void> deleteAllLocalData() async {
    final db = await instance.database;
    await db.delete('expenses');
    await db.delete('receipts');
    await db.delete('products');
    // Categorias podem ser mantidas, mas vamos recriar para consistência
    await db.delete('product_categories');
    await _insertDefaultCategories(db);
  }
}