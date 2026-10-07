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
                      '${NumberFormat('#,##0.00').format(provider.netBalance)} บาท',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: provider.netBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('รายรับ: ${NumberFormat('#,##0.00').format(provider.totalIncome)} ฿',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('รายจ่าย: ${NumberFormat('#,##0.00').format(provider.totalExpense)} ฿',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.transactions.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีข้อมูลรายรับ-รายจ่าย กดปุ่ม + ด้านล่างเพื่อเพิ่ม'),
                  );
                }
                return ListView.builder(
                  itemCount: provider.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = provider.transactions[index];
                    final isIncome = tx.type == TransactionType.income;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(tx.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx.amount)}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditTransactionScreen(transaction: tx),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () {
                                provider.deleteTransaction(tx.id!);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
        },
      ),
    );
  }
}
