import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finances/models/nfce.dart';
import 'package:http/http.dart' as http;
// Para parsear a data
import 'package:xml/xml.dart' as xml;
import '../models/nfce_item_detail.dart'; // Importa a nova classe

// A classe NfceData foi removida, usamos NotaFiscal diretamente

class NfceService {

  // Função auxiliar interna para buscar texto de forma segura
  String _getElementText(xml.XmlElement parent, String elementName, {String defaultValue = ''}) {
      try {
        // Usa .firstOrNull para evitar exceções se o elemento não for encontrado
        return parent.findElements(elementName).firstOrNull?.innerText ?? defaultValue;
      } catch (e) {
        print("Erro ao buscar elemento $elementName: $e");
        return defaultValue;
      }
  }


  Future<Nfce> fetchAndParseNfce(String url) async {
    try {
      // Adiciona um timeout à requisição para evitar travamentos
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        // Busca os elementos principais de forma mais segura
        final nfeElement = document.findAllElements('NFe').firstOrNull;
        if (nfeElement == null) throw Exception('Elemento <NFe> não encontrado no XML.');

        final infNFeElement = nfeElement.getElement('infNFe');
        if (infNFeElement == null) throw Exception('Elemento <infNFe> não encontrado no XML.');

        final ideElement = infNFeElement.getElement('ide');
        if (ideElement == null) throw Exception('Elemento <ide> não encontrado no XML.');

        final emitElement = infNFeElement.getElement('emit');
        if (emitElement == null) throw Exception('Elemento <emit> não encontrado no XML.');

        final totalElement = infNFeElement.getElement('total')?.getElement('ICMSTot');
        if (totalElement == null) throw Exception('Elemento <ICMSTot> não encontrado no XML.');

        final infAdicElement = infNFeElement.getElement('infAdic'); // Pode ser nulo

        // --- Extração dos Detalhes da Nota ---
        final String nfceKey = infNFeElement.getAttribute('Id')?.replaceAll('NFe', '') ?? '';
        final String storeName = _getElementText(emitElement, 'xNome', defaultValue: 'Loja Desconhecida');
        final String totalValueText = _getElementText(totalElement, 'vNF');
        final double totalValue = double.tryParse(totalValueText) ?? 0.0;
        final String dateText = _getElementText(ideElement, 'dhEmi');

        // Parse da data
        Timestamp date = Timestamp.now(); // Valor padrão
         try {
           // Formato ISO 8601 com timezone offset: 2025-09-24T17:46:33-03:00
            DateTime parsedDate = DateTime.parse(dateText);
            date = Timestamp.fromDate(parsedDate);
         } catch(e) {
           print("Erro ao parsear data da NFC-e ('$dateText'): $e. Usando data atual.");
         }

         // --- Extração das Informações Adicionais (Impostos) ---
        String taxInfo = '';
        if (infAdicElement != null) {
          taxInfo = _getElementText(infAdicElement, 'infCpl');
          // Tenta extrair apenas a parte dos tributos
           final tribRegex = RegExp(r'Trib.*? aprox: R\$[\d,\.]+ Federal.*? R\$[\d,\.]+ Estadual.*?Fonte IBPT');
           final match = tribRegex.firstMatch(taxInfo);
           if (match != null) {
             taxInfo = match.group(0)!; // Pega só a parte dos tributos
           } else {
             // Se não encontrar o padrão exato, tenta um padrão mais simples
             final simpleTribRegex = RegExp(r'Trib.*? aprox: R\$[\d,\.]+');
             final simpleMatch = simpleTribRegex.firstMatch(taxInfo);
             taxInfo = simpleMatch?.group(0) ?? ''; // Pega o que encontrar ou deixa vazio
           }
        }

        // --- Extração dos Itens ---
        final productsXml = infNFeElement.findAllElements('det');
        
        final List<NfceItemDetail> items = [];
        for (final product in productsXml) {
          final prodElement = product.getElement('prod');
          if (prodElement == null) continue; // Pula se não houver <prod>

          final String name = _getElementText(prodElement, 'xProd');
          final String qtyText = _getElementText(prodElement, 'qCom');
          final String unitPriceText = _getElementText(prodElement, 'vUnCom');
          final String totalPriceText = _getElementText(prodElement, 'vProd');

          final double quantity = double.tryParse(qtyText) ?? 0;
          final double unitPrice = double.tryParse(unitPriceText) ?? 0;
          final double totalPrice = double.tryParse(totalPriceText) ?? 0;

          if (name.isNotEmpty) {
            items.add(NfceItemDetail(
              name: name.trim(), // Remove espaços extras
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
            ));
          }
        }

        if (items.isEmpty && totalValue == 0) {
           throw Exception('Nenhum dado relevante (itens ou valor total) encontrado no XML da NFC-e.');
        }

        // Cria e retorna o objeto NotaFiscal completo
        return Nfce(
          nfceKey: nfceKey,
          storeName: storeName,
          totalValue: totalValue,
          date: date,
          taxInfo: taxInfo,
          items: items,
        );
      } else {
        throw Exception('Falha ao carregar a página da NFC-e. Código de status: ${response.statusCode}');
      }
    } on TimeoutException {
       throw Exception('Tempo limite excedido ao buscar dados da NFC-e.');
    } catch (e) {
       print("Erro detalhado no fetchAndParseNfce: $e");
       // Re-lança a exceção para ser tratada na UI, talvez com uma mensagem mais amigável
       throw Exception('Ocorreu um erro ao processar a NFC-e: ${e.toString()}');
    }
  }
}

