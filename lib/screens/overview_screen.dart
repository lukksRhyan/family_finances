import 'package:family_finances/styles/section_style.dart';
import 'package:family_finances/widgets/row_option.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import 'shopping_list_screen.dart';
import 'add_transaction_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});
  final bool mergeBalances = false;

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
    _endDate = DateTime(now.year, now.month + 2, 0);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _openAddTransactionScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionScreen(),
    );
  }

  void _openEditExpense(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionScreen(expenseToEdit: expense),
    );
  }

  void _openEditReceipt(BuildContext context, Receipt receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionScreen(receiptToEdit: receipt),
    );
  }

  void _confirmDeleteExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza de que deseja apagar a despesa "${expense.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final financeState = Provider.of<FinanceState>(context, listen: false);
                financeState.deleteExpense(expense.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Despesa apagada com sucesso!')),
                );
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteReceipt(BuildContext context, Receipt receipt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza de que deseja apagar a receita "${receipt.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final financeState = Provider.of<FinanceState>(context, listen: false);
                financeState.deleteReceipt(receipt.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receita apagada com sucesso!')),
                );
              },
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeState = Provider.of<FinanceState>(context);

    final filteredExpenses = financeState.expenses.where((e) {
      final expenseDate = e.date;
      final inclusiveEndDate =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      return !expenseDate.isBefore(_startDate) &&
          !expenseDate.isAfter(inclusiveEndDate);
    }).toList();

    final filteredReceipts = financeState.receipts.where((r) {
      final receiptDate = r.date;
      final inclusiveEndDate =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      return !receiptDate.isBefore(_startDate) &&
          !receiptDate.isAfter(inclusiveEndDate);
    }).toList();

    final totalReceitasAtuais = filteredReceipts
        .where((r) => !r.isFuture)
        .fold(0.0, (sum, item) => sum + item.value);
    final totalDespesasAtuais = filteredExpenses
        .where((e) => !e.isFuture)
        .fold(0.0, (sum, item) => sum + item.value);
    final totalAReceber = filteredReceipts
        .where((r) => r.isFuture)
        .fold(0.0, (sum, item) => sum + item.value);
    final totalAPagar = filteredExpenses
        .where((e) => e.isFuture)
        .fold(0.0, (sum, item) => sum + item.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyFinances'),
        leading: const Icon(Icons.account_balance_wallet),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildButtomsRow(context),
            const SizedBox(height: 16),
            Text(
              'Saldo no período: R\$ ${(totalReceitasAtuais - totalDespesasAtuais).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDateFilter(context),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: SectionStyle(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Saldo Atual'),
                  _buildBalanceSection(totalReceitasAtuais, totalDespesasAtuais),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 5,),
            _buildFutureBalanceSection(totalAReceber, totalAPagar),
            _buildSectionTitle('Despesas'),
            ...filteredExpenses.map((expense) => _buildExpenseRow(context, expense)),
            const Divider(height: 32),
            _buildSectionTitle('Receitas'),
            ...filteredReceipts.map((receipt) => _buildReceiptRow(context, receipt)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const ShoppingListScreen(),
          ));
        },
        backgroundColor: const Color(0xFF2A8782),
        tooltip: 'Abrir lista de compras',
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _buildButtomsRow(BuildContext context){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RowOption(title: "Lista de Compras", iconData: Icons.shopping_cart, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
          );
        }),
        RowOption(title: "Adicionar Transação", iconData: Icons.add, onTap: _openAddTransactionScreen),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Período: ', style: Theme.of(context).textTheme.titleMedium),
        TextButton(
          onPressed: () => _selectDateRange(context),
          child: Text(
            '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDateRange(context),
          tooltip: 'Selecionar período',
        ),
      ],
    );
  }

  Widget _buildBalanceSection(double receitas, double despesas) {
    final receitasPercent =
        (receitas + despesas == 0 ? 0 : (receitas / (receitas + despesas)) * 100).toDouble();
    final despesasPercent =
        (receitas + despesas == 0 ? 0 : (despesas / (receitas + despesas)) * 100).toDouble();
    final saldo = receitas - despesas;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receitas atuais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${receitas.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green)),
            const SizedBox(height: 8),
            const Text('Despesas atuais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('R\$ ${despesas.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.red)),
          ],
        ),
        SizedBox(
          height: 80,
          width: 80,
          child: PieChart(
            PieChartData(
              sections: saldo >= 0 ? [
                PieChartSectionData(
                    color: Colors.green,
                    value: receitasPercent,
                    radius: 15,
                    showTitle: false),
                PieChartSectionData(
                    color: Colors.red,
                    value: despesasPercent,
                    radius: 15,
                    showTitle: false),
              ] : [
                PieChartSectionData(
                    color: Colors.red[800],
                    value: despesasPercent,
                    radius: 15,
                    showTitle: false),
              ],
              centerSpaceRadius: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFutureBalanceSection(double aReceber, double aPagar) {
    final total = aReceber + aPagar;
    final aReceberPercent = (total == 0 ? 0 : (aReceber / total) * 100).toDouble();
    final aPagarPercent = (total == 0 ? 0 : (aPagar / total) * 100).toDouble();
    if (total == 0.0){
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: SectionStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('A Receber / A Pagar'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A Receber', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('R\$ ${aReceber.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 8),
                  const Text('A Pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('R\$ ${aPagar.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, color: Colors.red)),
                ],
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                          color: Colors.blue,
                          value: aReceberPercent,
                          radius: 15,
                          showTitle: false),
                      PieChartSectionData(
                          color: Colors.orange,
                          value: aPagarPercent,
                          radius: 15,
                          showTitle: false),
                    ],
                    centerSpaceRadius: 25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildExpenseRow(BuildContext context, Expense expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(expense.category.icon,
            color: expense.isFuture ? Colors.orange : Colors.red),
        title: Text(expense.title),
        subtitle: Text(expense.isFuture
            ? 'A pagar em ${DateFormat('dd/MM/yyyy').format(expense.date)}'
            : DateFormat('dd/MM/yyyy').format(expense.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('R\$ ${expense.value.toStringAsFixed(2)}',
                style: TextStyle(color: expense.isFuture ? Colors.orange : Colors.red)),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openEditExpense(context, expense),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteExpense(context, expense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(receipt.category.icon,
            color: receipt.isFuture ? Colors.blue : Colors.green),
        title: Text(receipt.title),
        subtitle: Text(receipt.isFuture
            ? 'A receber em ${DateFormat('dd/MM/yyyy').format(receipt.date)}'
            : DateFormat('dd/MM/yyyy').format(receipt.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('R\$ ${receipt.value.toStringAsFixed(2)}',
                style: TextStyle(color: receipt.isFuture ? Colors.blue : Colors.green)),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openEditReceipt(context, receipt),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteReceipt(context, receipt),
            ),
          ],
        ),
      ),
    );
  }
}