
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/receipt.dart';

enum RecurrencyType { monthly, weekly, custom }

class TransactionDetailScreen extends StatefulWidget {
  final Expense? expenseToShow;
  final Receipt? receiptToShow;

  const TransactionDetailScreen({super.key, this.expenseToShow, this.receiptToShow});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  

  @override
  void initState() {
    super.initState();
   
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.expenseToShow != null) ...[
              _buildDetailRow('Tipo:', 'Despesa'),
              _buildDetailRow('Título:', widget.expenseToShow!.title),
              _buildDetailRow('Valor:', 'R\$ ${widget.expenseToShow!.value.toStringAsFixed(2)}'),
              _buildDetailRow('Data:', DateFormat('dd/MM/yyyy').format(widget.expenseToShow!.date)),
              _buildDetailRow('Categoria:', widget.expenseToShow!.category.name),
              if (widget.expenseToShow!.note.isNotEmpty)
                _buildDetailRow('Nota:', widget.expenseToShow!.note),
              //_buildDetailRow('Recorrente:', widget.expenseToShow!.isRecurrent ? 'Sim' : 'Não'),
              if (widget.expenseToShow!.isRecurrent)
                _buildDetailRow('Tipo de Recorrência:', RecurrencyType.values[widget.expenseToShow!.recurrencyType!].toString().split('.').last),
              //_buildDetailRow('Parcelado:', widget.expenseToShow!.isInInstallments ? 'Sim' : 'Não'),
              if (widget.expenseToShow!.isInInstallments)
                _buildDetailRow('Parcelas:', widget.expenseToShow!.installmentCount.toString()),
            ] else if (widget.receiptToShow != null) ...[
              _buildDetailRow('Tipo:', 'Receita'),
              _buildDetailRow('Título:', widget.receiptToShow!.title),
              _buildDetailRow('Valor:', 'R\$ ${widget.receiptToShow!.value.toStringAsFixed(2)}'),
              _buildDetailRow('Data:', DateFormat('dd/MM/yyyy').format(widget.receiptToShow!.date)),
              _buildDetailRow('Categoria:', widget.receiptToShow!.category.name),
              //_buildDetailRow('Recorrente:', widget.receiptToShow!.isRecurrent ? 'Sim' : 'Não'),
              // Adicione mais detalhes da receita conforme necessário
            ] else ...[
              const Text('Nenhum detalhe de transação para exibir.', style: TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Fechar', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}