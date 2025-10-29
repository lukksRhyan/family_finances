import 'package:family_finances/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Classe para guardar os dados de um item (sem alterações)
class ProductCategory{
  final String name;
  final String icon;
  const ProductCategory({
    required this.name,
    required this.icon,
  });


}
class NoteProduct {
  final String name;
  final Product product;
  final double quantity;
  final double totalPrice;
  
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  NoteProduct({
    required this.name,
    required this.quantity,
    required this.totalPrice,
    required this.product,
  });
  @override
  String toString() {
    return '$quantity X $name a $product.option = $totalPrice}';
  }
}

class NfceData {
  final List<NoteProduct> items;
  final double totalValue;
  final String taxInfo; 
  final String nFNumber;
  NfceData({
    required this.items,
    required this.totalValue,
    required this.taxInfo,
    required this.nFNumber,
  });

  String itensList() {
    String result = '';
    for (var item in items) {
      result += item.toString() +'\n';
    }
    return result;
  }
}

class NfceService {
  /// Faz a requisição HTTP, analisa o XML e extrai os itens, valor total e impostos.
  Future<NfceData> fetchAndParseNfce(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);


        final nFNumberText = (() {
          try {
            final nFElement = document.findAllElements('nNF').first;
            return nFElement.innerText;
          } catch (e) { return ''; }
        })();
        // --- Extração dos Itens (sem grandes alterações) ---
        final productsXml = document.findAllElements('det');
        final List<NoteProduct> items = [];
        for (final product in productsXml) {
           // Função auxiliar interna (sem alterações)
           String getElementText(xml.XmlElement parent, String elementName) {
            try {
              return parent.findAllElements(elementName).first.innerText;
            } catch (e) { return ''; }
          }
           String getProdElementText(String elementName) => getElementText(product.getElement('prod')!, elementName);
           
          final String name = getProdElementText('xProd');
          final String qtyText = getProdElementText('qCom');
          final String unitPriceText = getProdElementText('vUnCom');
          final String totalPriceText = getProdElementText('vProd');

          final double quantity = double.tryParse(qtyText) ?? 0;
          final double unitPrice = double.tryParse(unitPriceText) ?? 0;
          final double totalPrice = double.tryParse(totalPriceText) ?? 0;

          if (name.isNotEmpty) {
            items.add(NoteProduct(
              name: name, quantity: quantity, unitPrice: unitPrice, totalPrice: totalPrice, category: ProductCategory(name: 'Default', icon: 'default_icon.png'),
            ));
          }
        }

        // --- Extração do Valor Total ---
         double totalValue = 0;
         try {
           final totalElement = document.findAllElements('vNF').first;
           totalValue = double.tryParse(totalElement.innerText) ?? 0;
         } catch(e) {/* Ignora se não encontrar */}

        // --- Extração das Informações Adicionais (Impostos) ---
        String taxInfo = '';
        try {
          // Procura por infCpl dentro de infAdic
      
          final infAdicElement = document.findAllElements('infAdic').firstOrNull;
          if (infAdicElement != null) {
              final infCplElement = infAdicElement.findAllElements('infCpl').firstOrNull;
              if (infCplElement != null) {
                  taxInfo = infCplElement.innerText.trim();
                  // Tenta extrair apenas a parte dos tributos se existir
                   final tribRegex = RegExp(r'Trib\. aprox: R\$.*Fonte IBPT');
                   final match = tribRegex.firstMatch(taxInfo);
                   if (match != null) {
                     taxInfo = match.group(0)!; // Pega só a parte dos tributos
                   }
              }
          }
        } catch (e) {/* Ignora se não encontrar */}


        if (items.isEmpty && totalValue == 0) {
           throw Exception('Nenhum dado relevante encontrado no XML da NFC-e.');
        }

        return NfceData(
          items: items,
          totalValue: totalValue,
          taxInfo: taxInfo,
          nFNumber: nFNumberText,
        );
      } else {
        throw Exception('Falha ao carregar a página da NFC-e. Código de status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

