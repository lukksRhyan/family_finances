// Para Timestamp
import 'product_category.dart';
import 'product_option.dart';

class Product {
  final String? id;
  int? localId; // ID do documento no Firestore
  final String name;
  final String nameLower; // Para buscas case-insensitive
  ProductCategory category; // Categoria do produto
  int? priority; // Prioridade (1-5, por exemplo), a ser definida pela IA
  List<ProductOption> options; // Histórico de compras/opções
  bool isChecked; // Para usar na lista de compras

  Product({
    this.id,
    this.localId,
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

  // Método para converter para Map (útil para Sqflite)
  Map<String, dynamic> toMapForSqlite() {
    return {
      'id': localId, // Usa o localId para o Sqflite
      'name': name,
      'nameLower': nameLower,
      'categoryId': category.id,
      'priority': priority,
      'options': ProductOption.encode(options), // Converte a lista de opções para String JSON
      'isChecked': isChecked ? 1 : 0, // SQLite não tem booleano, usa 0 ou 1
    };
  }

  // Método para converter de Map (útil para Sqflite)
  factory Product.fromMapForSqlite(Map<String, dynamic> map, ProductCategory category) {
    return Product(
      id: map['id']?.toString(), // O ID do Sqflite é int, mas o modelo usa String
      localId: map['id'] as int?,
      name: map['name'] as String,
      category: category,
      priority: map['priority'] as int?,
      options: ProductOption.decode(map['options'] as String?), // Decodifica a String JSON para lista de opções
      isChecked: (map['isChecked'] as int) == 1,
    );
  }
  Map<String, dynamic> toMapForFirestore() {
    return {
      'name': name,
      'nameLower': nameLower,
      'categoryId': category.id, // Guarda APENAS o ID da categoria
      'priority': priority,
      // Itera na lista de opções e chama o .toMapForFirestore() de cada uma
      'options': options.map((opt) => opt.toMapForFirestore()).toList(), 
      'isChecked': isChecked,
    };
  }

  factory Product.fromMapFromFirestore(Map<String, dynamic> map, String id, ProductCategory category) {
     var optionsList = <ProductOption>[];
    if (map['options'] is List) {
      // Itera pela lista de mapas e chama o construtor da ProductOption
      optionsList = (map['options'] as List)
          .map((e) => ProductOption.fromMapFromFirestore(e as Map<String, dynamic>))
          .toList();
    }
    
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: category, // Usa o objeto Categoria que foi passado
      priority: map['priority'],
      options: optionsList..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)), // Ordena
      isChecked: map['isChecked'] ?? false,
    );
  }
   // Método auxiliar para adicionar ou atualizar uma opção de compra
  void addOrUpdateOption(ProductOption newOption) {

    options.add(newOption);
    // Ordena as opções pela data da compra mais recente
    options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }
  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    int? priority,
    List<ProductOption>? options,
    bool? isChecked,
    int? localId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      options: options ?? this.options,
      isChecked: isChecked ?? this.isChecked,
    );
  }

}
 