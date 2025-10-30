import 'dart:convert';
import 'dart:async'; // Para StreamSubscription e temporizadores
import 'package:http/http.dart' as http;

/// Classe auxiliar para analisar a resposta JSON estruturada da IA.
/// Não é um modelo do Firestore, é apenas um DTO (Data Transfer Object).
class ClassifiedProduct {
  final String productName;
  final String categoryName;
  final int priority;

  ClassifiedProduct({
    required this.productName,
    required this.categoryName,
    required this.priority,
  });

  factory ClassifiedProduct.fromJson(Map<String, dynamic> json) {
    return ClassifiedProduct(
      productName: json['productName'] ?? 'Produto Desconhecido',
      categoryName: json['categoryName'] ?? 'Indefinida',
      priority: (json['priority'] as num? ?? 3).toInt(),
    );
  }
}

class GeminiService {
  // ATENÇÃO: Obtenha a sua chave de API no Google AI Studio
  // Execute a app com: flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final String model = 'gemini-1.5-flash-latest';
  final String _apiUrl;

  GeminiService() : _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey';

  /// Classifica uma lista de nomes de produtos e atribui-lhes prioridades.
  Future<List<ClassifiedProduct>> classifyProducts(List<String> productNames, List<String> categories) async {
    if (_apiKey.isEmpty) {
      throw Exception('Chave de API do Gemini não configurada. Use --dart-define=GEMINI_API_KEY=SUA_CHAVE');
    }

    // 1. O Prompt do Sistema: Define as regras para a IA
    final systemPrompt = """
      Você é um assistente de finanças pessoais especializado em classificar listas de compras no Brasil.
      Sua tarefa é analisar uma lista de nomes de produtos de uma nota fiscal e atribuir a cada um:
      1.  Uma categoria da lista fornecida.
      2.  Uma prioridade de 1 (essencial) a 5 (supérfluo).

      Categorias disponíveis: ${categories.join(', ')}
      Use a categoria "Indefinida" se nenhuma outra se aplicar.

      Níveis de Prioridade:
      1: Essencial (ex: Arroz, Feijão, Ovos, Papel Higiênico, Sabonete)
      2: Importante (ex: Frutas, Legumes, Carne, Café, Pão)
      3: Neutro (ex: Iogurte, Manteiga, Suco, Shampoo, Detergente)
      4. Dispensável (ex: Refrigerante, Salgadinhos, Biscoitos Recheados)
      5: Supérfluo/Luxo (ex: Vinho Caro, Chocolate Importado, Decoração)

      Responda APENAS com um objeto JSON contendo um array chamado "classifications".
      NÃO inclua markdown (```json ... ```) ou qualquer outro texto.
    """;

    // 2. O Prompt do Utilizador: Os dados a serem processados
    final userPrompt = "Classifique os seguintes produtos:\n${productNames.join('\n')}";

    // 3. O Schema da Resposta: Como queremos que a IA devolva os dados
    final responseSchema = {
      "type": "OBJECT",
      "properties": {
        "classifications": {
          "type": "ARRAY",
          "items": {
            "type": "OBJECT",
            "properties": {
              "productName": {"type": "STRING"},
              "categoryName": {"type": "STRING"},
              "priority": {"type": "NUMBER"}
            },
            "required": ["productName", "categoryName", "priority"]
          }
        }
      },
      "required": ["classifications"]
    };

    // 4. O Payload da Requisição
    final payload = {
      "systemInstruction": {
        "parts": [{"text": systemPrompt}]
      },
      "contents": [
        {"parts": [{"text": userPrompt}]}
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": responseSchema,
      }
    };

    // 5. A Chamada de API com Retentativa (Exponential Backoff)
    int retries = 0;
    while (retries < 3) { // Tenta até 3 vezes
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final candidate = body['candidates']?[0];
          
          if (candidate == null) {
            throw Exception('Resposta da API inválida: "candidates" não encontrado.');
          }

          final jsonText = candidate['content']?['parts']?[0]?['text'];
          if (jsonText == null) {
            throw Exception('Resposta da API inválida: "text" não encontrado.');
          }

          final Map<String, dynamic> result = jsonDecode(jsonText);
          final List<dynamic> classifications = result['classifications'] ?? [];
          
          return classifications
              .map((item) => ClassifiedProduct.fromJson(item as Map<String, dynamic>))
              .toList();

        } else if (response.statusCode == 429 || response.statusCode == 503) {
          // 429: Too Many Requests / 503: Service Unavailable (comum em picos)
          throw http.ClientException("Serviço indisponível ou limite de taxa atingido.", response.request?.url);
        } else {
          // Outros erros
          final errorBody = jsonDecode(response.body);
          throw Exception('Erro da API Gemini: ${response.statusCode} - ${errorBody['error']?['message'] ?? response.body}');
        }

      } catch (e) {
        retries++;
        if (e is TimeoutException || e is http.ClientException) {
          if (retries >= 3) rethrow; // Desiste após a última tentativa
          final delay = Duration(seconds: 2 * retries); // 2s, 4s
          print('Erro de rede ou timeout, tentando novamente em $delay... ($e)');
          await Future.delayed(delay);
        } else {
          // Erro de parsing ou outro erro inesperado
          print('Erro não recuperável no GeminiService: $e');
          rethrow; // Desiste imediatamente
        }
      }
    }
    // Se sair do loop (o que não deve acontecer)
    throw Exception('Falha ao classificar produtos após 3 tentativas.');
  }
}

