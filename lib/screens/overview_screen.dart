import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';

import '../styles/app_colors.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
// 1. Importar a tela de detalhes
import 'transaction_detail_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _filter = "all";
  
  // 2. Variável para controlar qual item está com as ações visíveis
  String? _activeActionId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceState>(context);

    final expenses = finance.expenses;
    final receipts = finance.receipts;

    final allTransactions = [
      ...expenses.map((e) => _TransactionItem.expense(e)),
      ...receipts.map((r) => _TransactionItem.receipt(r)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final visible = _filter == "all"
        ? allTransactions
        : allTransactions.where((t) => t.type == _filter).toList();

    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.value);
    final totalReceipts = receipts.fold(0.0, (sum, r) => sum + r.value);
    final balance = totalReceipts - totalExpenses;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.secondary,
      
      // Fecha as ações se clicar fora
      onDrawerChanged: (_) => setState(() => _activeActionId = null),
      
      endDrawer: const SizedBox(
        width: 300, 
        child: SettingsScreen(), 
      ),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text("Visão Geral"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() => _activeActionId = null);
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Adicionar"),
        onPressed: () {
          setState(() => _activeActionId = null);
          _openAddTransaction(context);
        },
      ),

      // GestureDetector no body para fechar as ações ao clicar no fundo
      body: GestureDetector(
        onTap: () {
          if (_activeActionId != null) {
            setState(() => _activeActionId = null);
          }
        },
        child: Column(
          children: [
            _buildHeader(balance, totalExpenses, totalReceipts),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 10),
            Expanded(
              child: visible.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final item = visible[i];
                        // Define um ID único para controle (Firestore ID ou Local ID)
                        final uniqueId = item.expense?.id ?? item.expense?.localId?.toString() ?? 
                                         item.receipt?.id ?? item.receipt?.localId?.toString() ?? 
                                         "temp_$i";
                        
                        // Decide se renderiza o Tile ou os Botões de Ação
                        if (_activeActionId == uniqueId) {
                          return _buildActionButtons(item, uniqueId);
                        }
                        return _buildTransactionTile(item, uniqueId);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _buildHeader, _buildSummaryTile, _buildFilterChips, _buildEmpty (iguais ao anterior) ...
  // (Mantenha esses métodos exatamente como estavam no seu código anterior para economizar espaço aqui)
  // VOU REPETIR APENAS O HEADER E CHIPS PARA CONTEXTO, MAS PODE MANTER O SEU SE NÃO MUDOU

  Widget _buildHeader(double balance, double expenses, double receipts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Saldo Atual", style: TextStyle(color: AppColors.onPrimary.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 5),
          Text("R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.onPrimary)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryTile("Receitas", receipts, Icons.arrow_upward, Colors.green.shade300),
              const SizedBox(width: 16),
              _buildSummaryTile("Despesas", expenses, Icons.arrow_downward, Colors.red.shade300),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, double value, IconData icon, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, color: Colors.white)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text("R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])])));
  }

  Widget _buildFilterChips() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [_chip("Todos", "all"), const SizedBox(width: 12), _chip("Despesas", "expense"), const SizedBox(width: 12), _chip("Receitas", "receipt")]));
  }

  Widget _chip(String label, String key) {
    final selected = _filter == key;
    return ChoiceChip(selected: selected, selectedColor: AppColors.primary, backgroundColor: Colors.grey.shade300, label: Text(label, style: TextStyle(color: selected ? AppColors.onPrimary : Colors.black87)), onSelected: (_) => setState(() => _filter = key));
  }

  Widget _buildEmpty() => Center(child: Text("Nenhuma transação ainda", style: TextStyle(color: Colors.grey.shade700, fontSize: 16)));


  // =============================================================================================
  // TILE NORMAL
  // =============================================================================================
  Widget _buildTransactionTile(_TransactionItem t, String uniqueId) {
    final isExpense = t.type == "expense";

    return GestureDetector(
      // 1. Tap normal -> Abre DETALHES
      onTap: () {
        setState(() => _activeActionId = null); // Limpa seleção se houver
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(
            expenseToShow: t.expense,
            receiptToShow: t.receipt,
          ))
        );
      },
      // 2. Long Press -> Ativa MODO AÇÃO (Muda a UI para botões)
      onLongPress: () {
        setState(() {
          _activeActionId = uniqueId;
        });
      },
      
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  isExpense ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                isExpense
                    ? t.expense!.category.icon
                    : t.receipt!.category.icon,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(DateFormat("dd MMM").format(t.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 8),
                      ..._buildBadges(t),
                    ],
                  )
                ],
              ),
            ),
            Text(
              (isExpense ? "-" : "+") +
                  " R\$ ${t.value.toStringAsFixed(2).replaceAll('.', ',')}",
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================================
  // BOTÕES DE AÇÃO (Substitui o Tile quando segurado)
  // =============================================================================================
  Widget _buildActionButtons(_TransactionItem t, String uniqueId) {
    return Container(
      height: 72, // Altura similar ao Tile original
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Botão Cancelar (Voltar ao normal) - Opcional, ou clique fora
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeActionId = null),
              child: const Center(child: Icon(Icons.close, color: Colors.grey)),
            ),
          ),
          
          // Botão EDITAR
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                setState(() => _activeActionId = null);
                _openAddTransaction(context, edit: t);
              },
              child: Container(
                color: Colors.blue.shade100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit, color: Colors.blue),
                    Text("Editar", style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ),
            ),
          ),

          // Botão EXCLUIR
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _confirmDelete(t),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12)
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.delete, color: Colors.red),
                    Text("Excluir", style: TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lógica de exclusão (igual, mas resetando o ID ativo)
  void _confirmDelete(_TransactionItem t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Transação"),
        content: Text("Tem certeza que deseja apagar '${t.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final state = Provider.of<FinanceState>(context, listen: false);
              try {
                if (t.type == 'expense') {
                  final id = t.expense!.id ?? t.expense!.localId.toString();
                  await state.deleteExpense(id);
                } else {
                  final id = t.receipt!.id ?? t.receipt!.localId.toString();
                  await state.deleteReceipt(id);
                }
                setState(() => _activeActionId = null); // Reseta UI
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removido com sucesso")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
                }
              }
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBadges(_TransactionItem t) {
    final List<Widget> badges = [];
    if (t.isShared) badges.add(_badge("Compartilhado", Colors.blue));
    if (t.isInInstallments) badges.add(_badge("${t.installmentCount}x", Colors.orange));
    if (t.isRecurrent) badges.add(_badge("Recorrente", Colors.purple));
    return badges;
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _openAddTransaction(BuildContext context, { _TransactionItem? edit }) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(expenseToEdit: edit?.expense, receiptToEdit: edit?.receipt)));
  }
}

// O _TransactionItem wrapper continua igual
class _TransactionItem {
  final String type;
  final DateTime date;
  final double value;
  final String title;
  final Expense? expense;
  final Receipt? receipt;

  bool get isRecurrent => expense?.isRecurrent == true || receipt?.isRecurrent == true;
  bool get isShared => expense?.isShared == true || receipt?.isShared == true;
  bool get isInInstallments => expense?.isInInstallments == true;
  int? get installmentCount => expense?.installmentCount;

  _TransactionItem.expense(Expense e) : type = "expense", date = e.date, value = e.value, title = e.title, expense = e, receipt = null;
  _TransactionItem.receipt(Receipt r) : type = "receipt", date = r.date, value = r.value, title = r.title, expense = null, receipt = r;
}