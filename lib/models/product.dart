// Para Timestamp
import 'product_category.dart';
import 'product_option.dart';

class Product {
  final String? id; // ID do documento no Firestore
  final String name;
  final String nameLower; // Para buscas case-insensitive
  ProductCategory category; // Categoria do produto
  int? priority; // Prioridade (1-5, por exemplo), a ser definida pela IA
  List<ProductOption> options; // Histórico de compras/opções
  bool isChecked; // Para usar na lista de compras

  Product({
    this.id,
    required this.name,
    required this.category,
    this.priority,
    this.options = const [],
    this.isChecked = false,
  }) : nameLower = name.toLowerCase(); 
  
  // Garante que nameLower é sempre minúsculo
  static Product notFound() {
    return Product(
      id: null,
      name: 'Produto não encontrado',
      category: ProductCategory.indefinida,
      priority: 0,
      options: [],
      isChecked: false,
    );
    }
  // Método para converter para Map (útil para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'categoryId': category.id, // Armazena apenas o ID da categoria
      'priority': priority,
      'options': options.map((opt) => opt.toMap()).toList(),
      'isChecked': isChecked,
    };
  }

  // Método para converter de Map (útil para Firestore)
  // Requer que as categorias sejam buscadas separadamente
  factory Product.fromMap(Map<String, dynamic> map, String id, ProductCategory category) {
     var optionsList = <ProductOption>[];
    if (map['options'] is List) {
      optionsList = (map['options'] as List)
          .map((e) => ProductOption.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: category, // Categoria é passada como parâmetro
      priority: map['priority'],
      options: optionsList,
      isChecked: map['isChecked'] ?? false,
    );
  }

   // Método auxiliar para adicionar ou atualizar uma opção de compra
  void addOrUpdateOption(ProductOption newOption) {
    // Lógica para verificar se uma opção similar já existe e atualizar,
    // ou apenas adicionar a nova. Pode comparar por loja e data, por exemplo.
    // Exemplo simples: sempre adiciona
    options.add(newOption);
    // Ordena as opções pela data da compra mais recente
    options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }
}
 