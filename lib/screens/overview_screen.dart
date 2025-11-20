import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'shopping_list_screen.dart';
import 'qr_code_scanner_screen.dart';
import '../services/nfce_service.dart';
import '../models/nfce.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _addTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionScreen(),
    );
  }

  void _openDetailsExpense(Expense e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionDetailScreen(expenseToShow: e),
    );
  }

  void _openDetailsReceipt(Receipt r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionDetailScreen(receiptToShow: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FinanceState>(context);

    final filteredExpenses = state.expenses.where((e) {
      final d = e.date;
      return !d.isBefore(_startDate) &&
          !d.isAfter(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59));
    }).toList();

    final filteredReceipts = state.receipts.where((r) {
      final d = r.date;
      return !d.isBefore(_startDate) &&
          !d.isAfter(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59));
    }).toList();

    final totalR = filteredReceipts.where((r) => !r.isFuture).fold(0.0, (x, y) => x + y.value);
    final totalD = filteredExpenses.where((e) => !e.isFuture).fold(0.0, (x, y) => x + y.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyFinances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Período:'),
                TextButton(
                  onPressed: () => _selectDateRange(context),
                  child: Text(
                    '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _selectDateRange(context),
                )
              ],
            ),
            Text(
              'Saldo: R\$ ${(totalR - totalD).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Despesas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ...filteredExpenses.map(
              (e) => ListTile(
                leading: Icon(e.category.icon, color: Colors.red),
                title: Text(e.title),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(e.date)),
                trailing: Text(
                  'R\$ ${e.value.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _openDetailsExpense(e),
              ),
            ),
            const Divider(height: 32),
            const Text('Receitas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ...filteredReceipts.map(
              (r) => ListTile(
                leading: Icon(r.category.icon, color: Colors.green),
                title: Text(r.title),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(r.date)),
                trailing: Text(
                  'R\$ ${r.value.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
                onTap: () => _openDetailsReceipt(r),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
