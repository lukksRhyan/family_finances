import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final String _apiUrl;

  // Mantendo o modelo que funcionou para você
  GeminiService() : _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

  Future<String> generateFinancialAnalysis({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryBreakdown,
    required List<String> recentTransactions,
    required String productHighlights, // <--- NOVO PARÂMETRO
  }) async {

    if (_apiKey.isEmpty) {
      return "⚠️ Erro: Chave de API não configurada. Verifique o launch.json.";
    }
    
    final breakdownString = categoryBreakdown.entries
        .map((e) => "- ${e.key}: R\$ ${e.value.toStringAsFixed(2)}")
        .join('\n');

    final recentString = recentTransactions.join('\n');

    // ATUALIZAÇÃO DO PROMPT
    final prompt = """
      Atue como um consultor financeiro pessoal experiente, direto e empático. Analise os dados financeiros do meu mês atual.
      
      DADOS GERAIS:
      - Receita: R\$ ${totalIncome.toStringAsFixed(2)}
      - Despesa: R\$ ${totalExpense.toStringAsFixed(2)}
      - Saldo: R\$ ${(totalIncome - totalExpense).toStringAsFixed(2)}
      
      GASTOS POR CATEGORIA:
      $breakdownString

      PRINCIPAIS PRODUTOS/ITENS COMPRADOS (Detalhe do que compõe as despesas):
      $productHighlights

      ÚLTIMAS TRANSAÇÕES MACRO:
      $recentString

      TAREFA:
      1. Resumo: Breve diagnóstico da saúde financeira.
      2. Análise de Hábitos (IMPORTANTE): Olhe para a lista de PRODUTOS. Identifique se há gastos supérfluos específicos (ex: muito gasto com bebida, doces, ou marcas caras) ou se os gastos são essenciais. Seja específico citando os produtos.
      3. Dicas Práticas: 3 ações concretas para economizar baseadas nesses produtos e categorias.
      
      FORMATO:
      Markdown (negrito, tópicos). Use emojis. Seja curto e vá direto ao ponto.
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
}