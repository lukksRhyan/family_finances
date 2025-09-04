import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/receipt.dart';

class DatabaseHelper {
  static final DatabaseHelper instance  = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('family_finances.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB
      );
  }
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER';


    await db.execute('''
    CREATE TABLE expenses (
      id INTEGER $idType,
      title $textType,
      value $doubleType,
      category_name $textType,
      category_icon $textType,
      note $textType,
      date $textType,
      is_recurrent $boolType,
      recurrency_id $intType,
      recurrency_type $intType,
      recurrent_interval_days $intType,
      is_in_installments $boolType,
      installment_count $intType,
    )
    ''');

    await db.execute('''
    CREATE TABLE receipts (
      id $idType,
      title $textType,
      value $doubleType,
      date $textType,
          )
    ''');
  }

  Future<int> createExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }
   Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> createReceipt(Receipt receipt) async {
    final db = await instance.database;
    return await db.insert('receipts', receipt.toMap());
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await instance.database;
    final result = await db.query('receipts', orderBy: 'date DESC');
    return result.map((json) => Receipt.fromMap(json)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}