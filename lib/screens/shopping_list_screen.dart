import 'package:family_finances/models/product_category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/product.dart'; // Importa o novo modelo Product
import '../models/product_option.dart'; // Importa ProductOption
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import 'package:intl/intl.dart'; // Para formatar data

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {

  @override
  Widget build(BuildContext context) {
    // Ouve as mudanças na lista de produtos do FinanceState
    // Usando o getter correto que adicionaremos ao FinanceState
    final products = Provider.of<FinanceState>(context).shoppingListProducts;
    const Color primaryColor = Color(0xFF2A8782); // Cor primária definida

    // Ordena os produtos alfabeticamente pelo nome para exibição
    products.sort((a, b) => a.nameLower.compareTo(b.nameLower));

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos / Lista de Compras')),
      body: products.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Nenhum produto cadastrado ainda.\nClique no botão + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 80.0), // Padding inferior para FAB
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductItem(context, product);
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AddProductScreen(), // Navega para a nova tela de adicionar produto
          ));
        },
        backgroundColor: primaryColor,
        tooltip: 'Adicionar Novo Produto', // Tooltip para acessibilidade
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget para construir cada item da lista de produtos
  Widget _buildProductItem(BuildContext context, Product product) {
    final financeState = Provider.of<FinanceState>(context, listen: false);
    // Pega a opção de compra mais recente (primeira da lista ordenada)
    final latestOption = product.options.isNotEmpty ? product.options.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card( // Usa Card para destacar cada item
        elevation: 2,
        child: ExpansionTile(
          key: ValueKey(product.id), // Chave única para o item
          leading: Checkbox(
            value: product.isChecked, // Estado do checkbox (para lista de compras)
            onChanged: (bool? value) {
              if (product.id != null) {
                // Atualiza o estado 'checked' no Firebase via FinanceState
                financeState.toggleProductChecked(product, value ?? false);
              }
            },
            activeColor: const Color(0xFF2A8782), // Cor do checkbox
          ),
          // Título com nome e categoria
          title: Row(
            children: [
              Icon(product.category.icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(child: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            ],
          ),
          // Subtítulo com informações da última compra
          subtitle: latestOption != null
            ? Text(
                'Última: ${latestOption.storeName} - R\$ ${latestOption.price.toStringAsFixed(2)} (${latestOption.quantity}) em ${DateFormat('dd/MM/yy').format(latestOption.purchaseDate.toDate())}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)
              )
            : const Text('Nenhuma compra registrada', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding interno
          children: [
            // Mostra o histórico das últimas opções/compras
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text('Histórico Recente:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                 const Divider(height: 8),
                 if (product.options.isEmpty)
                    const Text('Nenhum histórico de compra.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                 // Mostra as 3 últimas compras em ListTiles
                 ...product.options.take(3).map((opt) => ListTile(
                      dense: true, // Torna o ListTile mais compacto
                       contentPadding: EdgeInsets.zero, // Remove padding padrão
                       title: Text('${opt.storeName} - ${opt.brand}', style: const TextStyle(fontSize: 13)),
                       subtitle: Text('Qtd: ${opt.quantity} - Data: ${DateFormat('dd/MM/yy HH:mm').format(opt.purchaseDate.toDate())}', style: const TextStyle(fontSize: 11)), // Mostra data e hora
                       trailing: Text('R\$ ${opt.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                     )),
                  if (product.options.length > 3)
                     Padding(
                       padding: const EdgeInsets.only(top: 4.0),
                       child: Text('... (ver histórico completo no botão editar)', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                     ),
               ],
             ),
            // Botões de Ação alinhados à direita
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18), // Ícone menor
                  label: const Text('Editar/Histórico'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), // Menos padding
                  onPressed: () {
                    // Navega para a tela de edição, passando o produto
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => AddProductScreen(editProduct: product),
                    ));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  tooltip: 'Apagar Produto',
                  onPressed: () {
                    // Confirmação antes de apagar
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar Exclusão'),
                          content: Text('Tem certeza que deseja apagar o produto "${product.name}" e todo o seu histórico de compras? Esta ação não pode ser desfeita.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () {
                                 if (product.id != null) {
                                  // Chama o método deleteProduct no FinanceState
                                  financeState.deleteProduct(product.id!);
                                }
                                Navigator.of(ctx).pop(); // Fecha o diálogo
                                // Mostra confirmação
                                if(context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Produto "${product.name}" apagado.'))
                                  );
                                }
                              },
                               child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Nova Tela para Adicionar/Editar Produto ---
// (Esta tela foi movida para seu próprio arquivo ou mantida aqui por conveniência)
class AddProductScreen extends StatefulWidget {
  final Product? editProduct; // Recebe um produto existente para edição

  const AddProductScreen({super.key, this.editProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para validação do formulário
  late TextEditingController _nameController;
  late ProductCategory _selectedCategory;
  late List<ProductOption> _options; // Mantém as opções existentes/novas

  // Controllers para adicionar NOVA opção
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final List<String> _units = ['un','g', 'kg',  'ml', 'L', 'cx', 'pct', 'dz', 'm', 'cm']; // Unidades
  String _selectedUnit = 'un'; // Unidade padrão

  // Carrega as categorias disponíveis (idealmente viriam do Firestore ou config)
  final List<ProductCategory> _availableCategories = ProductCategory.standardCategories;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editProduct?.name ?? '');
    // Seleciona a categoria existente ou a indefinida como padrão
    _selectedCategory = _findCategoryById(widget.editProduct?.category.id ?? ProductCategory.indefinida.id);
    _options = widget.editProduct != null
        ? List<ProductOption>.from(widget.editProduct!.options) // Copia as opções existentes
        : [];
     // Ordena as opções existentes pela data mais recente
     _options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  // Função auxiliar para encontrar a categoria na lista _availableCategories pelo ID
  ProductCategory _findCategoryById(String id) {
    return _availableCategories.firstWhere((cat) => cat.id == id, orElse: () => ProductCategory.indefinida);
  }

  // Adiciona uma nova opção de compra à lista temporária _options
  void _addOption() {
    // Valida os campos antes de adicionar
    final priceString = _priceController.text.replaceAll(',', '.');
    final quantityString = _quantityController.text.replaceAll(',', '.');
    final price = double.tryParse(priceString);
    final quantityValue = double.tryParse(quantityString);

    if (_brandController.text.trim().isEmpty) {
      _showErrorSnackbar('O campo "Marca" não pode estar vazio.');
      return;
    }
     if (_storeController.text.trim().isEmpty) {
      _showErrorSnackbar('O campo "Loja" não pode estar vazio.');
      return;
    }
     if (quantityValue == null || quantityValue <= 0) {
       _showErrorSnackbar('A quantidade deve ser um número maior que zero.');
       return;
     }
      if (price == null || price <= 0) {
      _showErrorSnackbar('O preço deve ser um número maior que zero.');
      return;
    }


    setState(() {
      _options.insert(0, // Insere no início para mostrar a mais recente primeiro
        ProductOption(
          brand: _brandController.text.trim(),
          storeName: _storeController.text.trim(),
          price: price,
          quantity: '$quantityString $_selectedUnit', // Usa o valor parseado para garantir formato
          purchaseDate: Timestamp.now(), // Data da adição da opção
        )
      );
      // Limpa os campos após adicionar
      _brandController.clear();
      _storeController.clear();
      _priceController.clear();
      _quantityController.clear();
      _selectedUnit = _units[0]; // Reseta a unidade
      FocusScope.of(context).unfocus(); // Esconde o teclado
    });
  }

   // Remove uma opção da lista temporária _options
  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  // Salva o produto (novo ou editado) no Firestore
  void _saveProduct() {
     // Valida o formulário principal (Nome e Categoria)
     if (!(_formKey.currentState?.validate() ?? false)) {
        return; // Não salva se o formulário for inválido
     }

      final financeState = Provider.of<FinanceState>(context, listen: false);
      final product = Product(
        id: widget.editProduct!.id, // Mantém o ID se estiver editando
        name: _nameController.text.trim(),
        category: _selectedCategory,
        categoryId: _selectedCategory.id,
        options: _options, // Usa a lista de opções atualizada
        isChecked: widget.editProduct?.isChecked ?? false, // Mantém o estado 'checked'
        priority: widget.editProduct!.priority, // Mantém a prioridade se já existir
      );

      // Ordena as opções antes de salvar (garante a ordem no Firestore)
      product.options.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      // Mostra loading
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Chama o método apropriado no FinanceState (add ou update)
      Future<void> saveFuture = widget.editProduct != null
          ? financeState.updateProduct(product)
          : financeState.addProduct(product);

      saveFuture.then((_) {
            Navigator.of(context).pop(); // Fecha o loading
            Navigator.of(context).pop(); // Fecha a tela de Add/Edit
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.editProduct == null ? 'Produto adicionado!' : 'Produto atualizado!'), backgroundColor: Colors.green)
            );
        }).catchError((e){
             Navigator.of(context).pop(); // Fecha o loading
             print("Erro ao salvar produto: $e");
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red)
             );
        });
  }

  // Função auxiliar para mostrar SnackBar de erro
  void _showErrorSnackbar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange[800])
     );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editProduct == null ? 'Adicionar Produto' : 'Editar Produto')),
      body: Form( // Envolve com um Form para validação
         key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome do Produto (só editável se for novo)
              TextFormField( // Usa TextFormField para validação
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto*',
                   // Mostra o nome antigo se estiver editando e desabilitado
                  hintText: widget.editProduct != null ? 'Nome original: ${widget.editProduct!.name}' : null,
                ),
                enabled: widget.editProduct == null, // Desabilita edição do nome se já existe
                textCapitalization: TextCapitalization.words,
                validator: (value) { // Validação simples de nome não vazio
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome do produto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Seleção de Categoria
              DropdownButtonFormField<ProductCategory>(
                initialValue: _selectedCategory,
                items: _availableCategories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Row(children: [Icon(cat.icon, size: 20, color: Colors.grey[700]), const SizedBox(width: 8), Text(cat.name)]),
                )).toList(),
                onChanged: (cat) {
                  if (cat != null) {
                    setState(() => _selectedCategory = cat);
                  }
                },
                decoration: const InputDecoration(labelText: 'Categoria*', border: OutlineInputBorder()),
                 validator: (value) { // Validação da categoria
                  if (value == null || value.id == ProductCategory.indefinida.id) {
                    return 'Por favor, selecione uma categoria válida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Seção para Adicionar Nova Opção de Compra
              Text('Adicionar Nova Opção/Compra', style: Theme.of(context).textTheme.titleMedium),
              Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                       Row(
                        children: [
                          Expanded(child: TextField(controller: _brandController, decoration: const InputDecoration(labelText: 'Marca*'), textCapitalization: TextCapitalization.words,)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _storeController, decoration: const InputDecoration(labelText: 'Loja*'), textCapitalization: TextCapitalization.words,)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end, // Alinha itens na base
                        children: [
                          Expanded(
                            flex: 3, // Mais espaço para quantidade
                            child: TextField(
                               controller: _quantityController,
                               decoration: const InputDecoration(labelText: 'Qtd*', hintText: 'Ex: 500'),
                               keyboardType: const TextInputType.numberWithOptions(decimal: true), // Permite decimal
                             ),
                          ),
                          const SizedBox(width: 8),
                          // Dropdown de Unidades
                          DropdownButton<String>(
                              value: _selectedUnit,
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (value) {
                                if(value != null) setState(() => _selectedUnit = value);
                              },
                               underline: Container(), // Remove linha padrão
                               style: Theme.of(context).textTheme.bodyLarge,
                            ),
                           const SizedBox(width: 8),
                          Expanded(
                            flex: 2, // Menos espaço para preço
                            child: TextField(
                               controller: _priceController,
                               decoration: const InputDecoration(labelText: 'Preço*', prefixText: 'R\$ '),
                               keyboardType: const TextInputType.numberWithOptions(decimal: true),
                             ),
                          ),
                          // Botão Adicionar Opção
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 28),
                            tooltip: 'Adicionar esta opção de compra',
                            onPressed: _addOption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 16),

              // Lista de Opções Adicionadas/Existentes
              Text('Histórico de Compras (${_options.length}):', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: _options.isEmpty
                  ? Center(child: Text(widget.editProduct == null ? 'Nenhuma opção adicionada ainda.' : 'Nenhum histórico de compra registrado.'))
                  : ListView.builder(
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        // A lista _options já está ordenada por data descendente
                        final opt = _options[index];
                        return Card(
                           margin: const EdgeInsets.symmetric(vertical: 4),
                           child: ListTile(
                            dense: true,
                            title: Text('${opt.brand} - ${opt.storeName}', style: const TextStyle(fontSize: 14)),
                            subtitle: Text('Qtd: ${opt.quantity} - Data: ${DateFormat('dd/MM/yy HH:mm').format(opt.purchaseDate.toDate())}', style: const TextStyle(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('R\$ ${opt.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                 IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  tooltip: 'Remover esta compra do histórico',
                                  // Confirmação antes de remover opção
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remover Compra'),
                                      content: const Text('Tem certeza que deseja remover esta entrada do histórico?'),
                                      actions: [
                                         TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                                         TextButton(onPressed: (){
                                           _removeOption(index); // Remove da lista temporária
                                            Navigator.of(ctx).pop();
                                         }, child: const Text('Remover', style: TextStyle(color: Colors.red)))
                                      ],
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 16),

              // Botão Salvar
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).primaryColor,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                child: Text(widget.editProduct == null ? 'Salvar Novo Produto' : 'Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

