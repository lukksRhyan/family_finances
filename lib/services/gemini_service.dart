import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final String _apiUrl;

  // CORREÇÃO FINAL: Usando o modelo exato listado no seu terminal
  GeminiService() : _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

  // --- NOVO MÉTODO: Análise Financeira ---
  Future<String> generateFinancialAnalysis({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryBreakdown,
    required List<String> recentTransactions,
  }) async {

    if (_apiKey.isEmpty) {
      return "⚠️ Erro: Chave de API não configurada. Verifique o launch.json.";
    }
    
    // 1. Construção do Prompt
    final breakdownString = categoryBreakdown.entries
        .map((e) => "- ${e.key}: R\$ ${e.value.toStringAsFixed(2)}")
        .join('\n');

    final recentString = recentTransactions.join('\n');

    final prompt = """
      Atue como um consultor financeiro pessoal experiente e empático. Analise os dados financeiros abaixo do meu mês atual e gere um relatório curto e prático.
      
      DADOS:
      - Receita Total: R\$ ${totalIncome.toStringAsFixed(2)}
      - Despesa Total: R\$ ${totalExpense.toStringAsFixed(2)}
      - Saldo: R\$ ${(totalIncome - totalExpense).toStringAsFixed(2)}
      
      GASTOS POR CATEGORIA:
      $breakdownString

      ÚLTIMAS TRANSAÇÕES (Amostra):
      $recentString

      TAREFA:
      1. Resumo da Situação: Diga se estou no azul ou vermelho e quão saudável isso parece.
      2. Análise de Gastos: Aponte onde estou gastando muito (baseado nas categorias).
      3. Dicas Práticas: Dê 3 sugestões concretas para economizar no próximo mês baseadas nesses dados específicos.
      
      FORMATO:
      Responda em Markdown (use negrito, tópicos). Seja direto, amigável e use emojis.
    """;

    final payload = {
      "contents": [
        {"parts": [{"text": prompt}]}
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? "A IA não retornou nenhuma resposta.";
      } else {
        return "Erro na API (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "Erro de conexão: $e";
    }
  }
  
  // Pode remover ou manter a função listAvailableModels se quiser usar no futuro para debug
}