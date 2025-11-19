import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/expense.dart';
import 'models/receipt.dart';
import 'models/product.dart';
import 'models/product_category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    return _database!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'family_finances.db');

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE expenses (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          title TEXT,
          value REAL,
          category_name TEXT,
          category_icon INTEGER,
          note TEXT,
          date TEXT,
          isRecurrent INTEGER,
          recurrencyId INTEGER,
          recurrencyType INTEGER,
          recurrentIntervalDays INTEGER,
          isInInstallments INTEGER,
          installmentCount INTEGER,
          isShared INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE receipts (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          title TEXT,
          value REAL,
          categoryId TEXT,
          categoryName TEXT,
          date TEXT,
          isRecurrent INTEGER,
          recurrencyType INTEGER,
          isShared INTEGER,
          sharedFromUid TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE productCategories (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          name TEXT,
          iconCodePoint INTEGER,
          iconFontFamily TEXT,
          defaultPriority INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE products (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          name TEXT,
          categoryId TEXT,
          optionsJson TEXT,
          isChecked INTEGER,
          priority INTEGER
        )
      ''');
    });
  }

  Future<Expense> createExpense(Expense expense) async {
    final db = await database;
    final insertedId = await db.insert('expenses', {
      ...expense.toMapForSqlite(),
      'id': expense.id,
      'isShared': expense.isShared ? 1 : 0,
    });
    return expense.copyWith(localId: insertedId);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map((map) => Expense.fromMapForSqlite(map)).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      {
        ...expense.toMapForSqlite(),
        'id': expense.id,
        'isShared': expense.isShared ? 1 : 0,
      },
      where: 'localId = ?',
      whereArgs: [expense.localId],
    );
  }

  Future<void> deleteExpense(int localId) async {
    final db = await database;
    await db.delete('expenses', where: 'localId = ?', whereArgs: [localId]);
  }

  Future<Receipt> createReceipt(Receipt receipt) async {
    final db = await database;
    final insertedId = await db.insert('receipts', {
      ...receipt.toMapForSqlite(),
      'id': receipt.id,
      'categoryId': receipt.category.id,
      'categoryName': receipt.category.name,
      'isShared': receipt.isShared ? 1 : 0,
    });
    return receipt.copyWith(localId: insertedId);
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final rows = await db.query('receipts', orderBy: 'date DESC');
    return rows.map((map) => Receipt.fromMapForSqlite(map)).toList();
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await database;
    await db.update(
      'receipts',
      {
        ...receipt.toMapForSqlite(),
        'id': receipt.id,
        'categoryId': receipt.category.id,
        'categoryName': receipt.category.name,
        'isShared': receipt.isShared ? 1 : 0,
      },
      where: 'localId = ?',
      whereArgs: [receipt.localId],
    );
  }

  Future<void> deleteReceipt(int localId) async {
    final db = await database;
    await db.delete('receipts', where: 'localId = ?', whereArgs: [localId]);
  }

  Future<List<ProductCategory>> getAllProductCategories() async {
    final db = await database;
    final rows = await db.query('productCategories');
    return rows.map((map) => ProductCategory.fromMapForSqlite(map)).toList();
  }

  Future<void> createProductCategory(ProductCategory category) async {
    final db = await database;
    await db.insert('productCategories', category.toMapForSqlite());
  }

  Future<Product> createProduct(Product product) async {
    final db = await database;
    final insertedId = await db.insert('products', {
      ...product.toMapForSqlite(),
      'id': product.id,
      'optionsJson': product.options.map((o) => o.toMap()).toList().toString(),
    });
    return product.copyWith(localId: insertedId);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map((map) {
      final category = ProductCategory.indefinida;
      return Product.fromMapForSqlite(map, category);
    }).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      {
        ...product.toMapForSqlite(),
        'id': product.id,
        'optionsJson': product.options.map((o) => o.toMap()).toList().toString(),
      },
      where: 'localId = ?',
      whereArgs: [product.localId],
    );
  }

  Future<void> deleteProduct(int localId) async {
    final db = await database;
    await db.delete('products', where: 'localId = ?', whereArgs: [localId]);
  }

  Future<void> deleteAllLocalData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('receipts');
    await db.delete('products');
    await db.delete('productCategories');
  }
}
