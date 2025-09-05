import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import '../models/shopping_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  int? expandedIndex;
  int selectedOptionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shoppingList = Provider.of<FinanceState>(context).shoppingList;
    const Color primaryColor = Color(0xFF2A8782);

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Compras')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...shoppingList.asMap().entries.map((entry) => _buildShoppingItem(context, entry.key, entry.value)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddShoppingItemScreen(),
          ));
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildShoppingItem(BuildContext context, int index, ShoppingItem item) {
    final isExpanded = expandedIndex == index;
    List<String> brands = item.options.map((o) => o.brand).toSet().toList();
    List<String> stores = item.options.map((o) => o.store).toSet().toList();
    List<String> quantities = item.options.map((o) => o.quantity).toSet().toList();

    String selectedBrand = brands.isNotEmpty ? brands[0] : '';
    String selectedStore = stores.isNotEmpty ? stores[0] : '';
    String selectedQuantity = quantities.isNotEmpty ? quantities[0] : '';

    ShoppingItemOption? selectedOption;

    void updateSelectedOption() {
      selectedOption = item.options.firstWhere(
        (o) =>
            o.brand == selectedBrand &&
            o.store == selectedStore &&
            o.quantity == selectedQuantity,
        orElse: () => item.options[0],
      );
    }

    if (item.options.isNotEmpty) {
      updateSelectedOption();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        key: Key(item.name),
        initiallyExpanded: isExpanded,
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (bool? value) {
            Provider.of<FinanceState>(context, listen: false).toggleShoppingItemChecked(index, value!);
          },
          activeColor: const Color(0xFF2A8782),
        ),
        title: Text(item.name, style: const TextStyle(fontSize: 16)),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index : null;
            selectedOptionIndex = 0;
          });
        },
        children: [
          if (item.options.isNotEmpty && isExpanded)
            StatefulBuilder(
              builder: (context, setStateDropdown) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Filtrar opções:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedBrand,
                            items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (value) {
                              setStateDropdown(() {
                                selectedBrand = value!;
                                updateSelectedOption();
                              });
                            },
                            isExpanded: true,
                            hint: const Text('Marca'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedStore,
                            items: stores.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (value) {
                              setStateDropdown(() {
                                selectedStore = value!;
                                updateSelectedOption();
                              });
                            },
                            isExpanded: true,
                            hint: const Text('Estabelecimento'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedQuantity,
                            items: quantities.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                            onChanged: (value) {
                              setStateDropdown(() {
                                selectedQuantity = value!;
                                updateSelectedOption();
                              });
                            },
                            isExpanded: true,
                            hint: const Text('Quantidade'),
                          ),
                        ),
                      ],
                    ),
                    if (selectedOption != null)
                      ListTile(
                        title: Text('${selectedOption!.brand} - ${selectedOption!.store}'),
                        subtitle: Text('Quantidade: ${selectedOption!.quantity}'),
                        trailing: Text('R\$ ${selectedOption!.price.toStringAsFixed(2)}'),
                      ),
                  ],
                );
              },
            ),
          if (item.options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Sem opções cadastradas'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => AddShoppingItemScreen(editItem: item, editItemIndex: index),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddShoppingItemScreen extends StatefulWidget {
  final ShoppingItem? editItem;
  final int? editItemIndex;
  const AddShoppingItemScreen({super.key, this.editItem, this.editItemIndex});

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  late TextEditingController _nameController;
  late List<ShoppingItemOption> _options;
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // NOVO: Unidades disponíveis
  final List<String> _units = ['g', 'kg', 'un', 'ml', 'L', 'cx', 'pct'];
  String _selectedUnit = 'g';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editItem?.name ?? '');
    _options = widget.editItem != null
        ? List<ShoppingItemOption>.from(widget.editItem!.options)
        : [];
  }

  void _addOption() {
    if (_brandController.text.isNotEmpty &&
        _storeController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty) {
      setState(() {
        _options.add(ShoppingItemOption(
          brand: _brandController.text,
          store: _storeController.text,
          price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0,
          quantity: '${_quantityController.text} $_selectedUnit',
        ));
        _brandController.clear();
        _storeController.clear();
        _priceController.clear();
        _quantityController.clear();
        _selectedUnit = _units[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedOptionIndex = 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.editItem == null ? 'Adicionar Item' : 'Editar Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do produto'),
              enabled: widget.editItem == null,
            ),
            const SizedBox(height: 16),
            const Text('Opções (marca, estabelecimento, quantidade, valor):', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _storeController,
                    decoration: const InputDecoration(labelText: 'Estabelecimento'),
                  ),
                ),
              ]),
              Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(labelText: 'Quantidade'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: _selectedUnit,
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                          });
                        },
                        underline: Container(),
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Preço'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addOption,
                ),
              ],
            ),
            ..._options.map((opt) => ListTile(
                  title: Text('${opt.brand} - ${opt.store}'),
                  subtitle: Text('Quantidade: ${opt.quantity}'),
                  trailing: Text('R\$ ${opt.price.toStringAsFixed(2)}'),
                )),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final financeState = Provider.of<FinanceState>(context, listen: false);
                  final item = ShoppingItem(
                    name: _nameController.text,
                    options: _options,
                    isChecked: widget.editItem?.isChecked ?? false,
                  );

                  if (widget.editItemIndex != null) {
                    financeState.updateShoppingItem(widget.editItemIndex!, item);
                  } else {
                    financeState.addShoppingItem(item);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text(widget.editItem == null ? 'Salvar' : 'Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }
}


