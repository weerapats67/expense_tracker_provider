enum TransactionType { income, expense }

class MyTransaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;

  MyTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory MyTransaction.fromMap(Map<String, dynamic> map) {
    return MyTransaction(
      id: map['id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.byName(map['type'] as String),
    );
  }
}
```[cite: 17, 34, 35]

---

### 2. `lib/providers/transaction_provider.dart`
```dart
// lib/providers/transaction_provider.dart
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
```[cite: 33, 35, 36]

---

### 3. `lib/screens/add_edit_transaction_screen.dart`
```dart
// lib/screens/add_edit_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final MyTransaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late DateTime _date;
  late TransactionType _type;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _title = widget.transaction!.title;
      _amount = widget.transaction!.amount;
      _date = widget.transaction!.date;
      _type = widget.transaction!.type;
    } else {
      _title = '';
      _amount = 0.0;
      _date = DateTime.now();
      _type = TransactionType.expense;
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = context.read<TransactionProvider>();

      if (widget.transaction == null) {
        provider.addTransaction(_title, _amount, _date, _type);
      } else {
        provider.updateTransaction(widget.transaction!.id!, _title, _amount, _date, _type);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('รายจ่าย'),
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('รายรับ'),
                    icon: Icon(Icons.add_circle, color: Colors.green),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อรายการ';
                  }
                  return null;
                },
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'กรุณากรอกตัวเลขจำนวนเงินที่ถูกต้อง';
                  }
                  if (double.parse(value) <= 0) {
                    return 'จำนวนเงินต้องมากกว่า 0';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text('วันที่: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _date = pickedDate;
                        });
                      }
                    },
                    child: const Text('เปลี่ยนวันที่'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'บันทึกการแก้ไข' : 'บันทึกข้อมูล'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```[cite: 37]

---

### 4. `lib/screens/transaction_list_screen.dart`
```dart
// lib/screens/transaction_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/my_transaction.dart';
import '../providers/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แอปบัญชีรายรับ-รายจ่าย'),
      ),
      body: Column(
        children: [
          Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    const Text('ยอดเงินคงเหลือสุทธิ', style: TextStyle(fontSize: 16)),
                    Text(
                      '
