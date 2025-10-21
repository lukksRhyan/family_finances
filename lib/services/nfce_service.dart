import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// A classe ScrapedItem permanece a mesma
class ScrapedItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  ScrapedItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class NfceService {
  /// Faz a requisição HTTP para a URL da NFC-e, analisa o XML e extrai os itens.
  Future<List<ScrapedItem>> fetchAndParseNfce(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 1. Analisa a resposta como um documento XML
        final document = xml.XmlDocument.parse(response.body);

        // 2. Encontra todos os elementos <det> (detalhe do produto)
        final products = document.findAllElements('det');
        final List<ScrapedItem> items = [];

        for (final product in products) {
          // Função auxiliar para encontrar e obter o valor de um nó filho
          String getElementText(String elementName) {
            try {
              return product.findAllElements(elementName).first.innerText;
            } catch (e) {
              return ''; // Retorna string vazia se o elemento não for encontrado
            }
          }

          // 3. Extrai os dados de cada produto
          final String name = getElementText('xProd');
          final String qtyText = getElementText('qCom');
          final String unitPriceText = getElementText('vUnCom');
          final String totalPriceText = getElementText('vProd');
          
          // Converte os textos para números
          final double quantity = double.tryParse(qtyText) ?? 0;
          final double unitPrice = double.tryParse(unitPriceText) ?? 0;
          final double totalPrice = double.tryParse(totalPriceText) ?? 0;
          
          if (name.isNotEmpty) {
            ScrapedItem newItem = ScrapedItem(
              name: name,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            ); 
            items.add(newItem);
            print(newItem.name);
          }
        }
        
        if (items.isEmpty) {
          throw Exception('Nenhum produto encontrado no XML da NFC-e.');
        }

        return items;
      } else {
        throw Exception('Falha ao carregar a página da NFC-e. Código de status: ${response.statusCode}');
      }
    } catch (e) {
      // Propaga o erro para a interface do utilizador.
      rethrow;
    }
  }
}

