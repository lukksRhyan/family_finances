// lib/database_helper.dart
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

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      // expenses
      await db.execute('''
        CREATE TABLE expenses (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          title TEXT,
          value REAL,
          categoryId TEXT,
          categoryName TEXT,
          note TEXT,
          date TEXT,
          isRecurrent INTEGER,
          isInInstallments INTEGER,
          installmentCount INTEGER,
          recurrencyType INTEGER,
          recurrentIntervalDays INTEGER,
          isShared INTEGER,
          sharedFromUid TEXT
        )
      ''');

      // receipts
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

      // product categories
      await db.execute('''
        CREATE TABLE productCategories (
          localId INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT,
          name TEXT,
          iconCodePoint INTEGER
        )
      ''');

      // products
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

  // --- Expenses ---
  Future<Expense> createExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('expenses', {
      ...expense.toMapForSqlite(),
      'id': expense.id,
    });
    // Retorna com localId preenchido corretamente
    return expense.copyWith(id: expense.id, localId: id);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map((r) {
      // add localId to map for factory
      final map = Map<String, dynamic>.from(r);
      map['localId'] = r['localId'];
      return Expense.fromMapForSqlite(map);
    }).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update('expenses', expense.toMapForSqlite()..['id'] = expense.id, where: 'localId = ?', whereArgs: [expense.localId]);
  }

  Future<void> deleteExpense(int localId) async {
    final db = await database;
    await db.delete('expenses', where: 'localId = ?', whereArgs: [localId]);
  }

  Future<void> deleteAllLocalData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('receipts');
    await db.delete('products');
    await db.delete('productCategories');
  }

  // --- Receipts ---
  Future<Receipt> createReceipt(Receipt receipt) async {
    final db = await database;
    final id = await db.insert('receipts', {
      ...receipt.toMapForSqlite(),
      'id': receipt.id,
    });
    return receipt.copyWith(id: receipt.id, localId: id);
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final rows = await db.query('receipts', orderBy: 'date DESC');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['localId'] = r['localId'];
      return Receipt.fromMapForSqlite(map);
    }).toList();
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await database;
    await db.update('receipts', receipt.toMapForSqlite()..['id'] = receipt.id, where: 'localId = ?', whereArgs: [receipt.localId]);
  }

  Future<void> deleteReceipt(int localId) async {
    final db = await database;
    await db.delete('receipts', where: 'localId = ?', whereArgs: [localId]);
  }

  // --- Product Categories ---
  Future<List<ProductCategory>> getAllProductCategories() async {
    final db = await database;
    final rows = await db.query('productCategories');
    return rows.map((r) {
      return ProductCategory.fromMapForSqlite({...r, 'id': r['id']?.toString()});
    }).toList();
  }

  Future<void> createProductCategory(ProductCategory category) async {
    final db = await database;
    await db.insert('productCategories', {
      'id': category.id,
      'name': category.name,
      'iconCodePoint': category.icon.codePoint,
    });
  }

  // --- Products ---
  Future<Product> createProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', {
      ...product.toMapForSqlite(),
      'id': product.id,
    });
    return product.copyWith(id: product.id, localId: id);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    // Category resolution should be done by caller (we can't guess categories here)
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      return Product.fromMapForSqlite(map);
    }).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMapForSqlite()..['id'] = product.id, where: 'localId = ?', whereArgs: [product.localId]);
  }

  Future<void> deleteProduct(int localId) async {
    final db = await database;
    await db.delete('products', where: 'localId = ?', whereArgs: [localId]);
  }
}
