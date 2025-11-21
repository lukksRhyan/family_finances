import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Se não instalou, use Text() normal

import '../models/finance_state.dart';
import '../services/gemini_service.dart';
import '../styles/app_colors.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String? _analysisResult;
  bool _isLoading = false;

  Future<void> _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    try {
      final state = Provider.of<FinanceState>(context, listen: false);
      final gemini = GeminiService();

      // 1. Preparar dados das despesas por categoria
      final Map<String, double> breakdown = {};
      for (var e in state.expenses) {
        // Considera apenas despesas atuais (não futuras)
        if (!e.isFuture) {
          breakdown[e.category.name] = (breakdown[e.category.name] ?? 0) + e.value;
        }
      }

      // 2. Pegar amostra de transações recentes (últimas 5)
      final recent = state.expenses
          .where((e) => !e.isFuture)
          .take(5)
          .map((e) => "${e.title} (R\$ ${e.value.toStringAsFixed(2)})")
          .toList();

      // 3. Chamar IA
      final result = await gemini.generateFinancialAnalysis(
        totalIncome: state.totalReceitasAtuais,
        totalExpense: state.totalDespesasAtuais,
        categoryBreakdown: breakdown,
        recentTransactions: recent,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = "Erro ao gerar análise: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text("Consultor IA"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CARD DE INTRODUÇÃO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 40, color: Colors.purple),
                  const SizedBox(height: 12),
                  const Text(
                    "Análise Inteligente",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "A IA vai analisar seus gastos do mês atual e sugerir onde economizar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (!_isLoading)
                    ElevatedButton(
                      onPressed: _runAnalysis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Gerar Relatório Agora"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ÁREA DE RESULTADO
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.purple),
                          SizedBox(height: 16),
                          Text("Consultando a IA..."),
                        ],
                      ),
                    )
                  : _analysisResult == null
                      ? const Center(
                          child: Text(
                            "Nenhuma análise gerada ainda.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.withOpacity(0.2)),
                          ),
                          child: Markdown(
                            data: _analysisResult!,
                            styleSheet: MarkdownStyleSheet(
                              h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                              h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              p: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}