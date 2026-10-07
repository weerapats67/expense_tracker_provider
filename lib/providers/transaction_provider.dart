import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  static const String _dbName = 'expenses.db';
  static const String _tableName = 'transactions';

  Database? _database;
  List<MyTransaction> _transactions = [];

  List<MyTransaction> get transactions => [..._transactions];

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  TransactionProvider() {
    fetchAndSetTransactions();
  }

  Future<void> _initDatabase() async {
    if (_database != null) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE $_tableName('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title TEXT, '
            'amount REAL, '
            'date TEXT, '
            'type TEXT)',
          );
        },
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  Future<void> fetchAndSetTransactions() async {
    await _initDatabase();
    if (_database == null) return;

    final dataList = await _database!.query(_tableName, orderBy: 'date DESC');
    _transactions = dataList.map((item) => MyTransaction.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addTransaction(String title, double amount, DateTime date, TransactionType type) async {
    await _initDatabase();
    if (_database == null) return;

    final newTransaction = MyTransaction(
      title: title,
      amount: amount,
      date: date,
      type: type,
    );

    await _database!.insert(_tableName, newTransaction.toMap());
    await fetchAndSetTransactions();
  }

  Future<void> updateTransaction(int id, String title, double amount, DateTime date, TransactionType type) async {
    await _initDatabase();
    if (_database == null) return;

    final updatedTx = MyTransaction(
      id: id,
      title: title,
      amount: amount,
      date: date,
      type: type,
    );

    await _database!.update(
      _tableName,
      updatedTx.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAndSetTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _initDatabase();
    if (_database == null) return;

    await _database!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAndSetTransactions();
  }
}
