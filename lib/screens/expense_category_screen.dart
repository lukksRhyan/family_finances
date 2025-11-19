import 'package:flutter/material.dart';
import '../models/expense_category.dart';

class AddExpenseWithCategoryScreen extends StatefulWidget {
  const AddExpenseWithCategoryScreen({super.key});

  @override
  State<AddExpenseWithCategoryScreen> createState() => _AddExpenseWithCategoryScreenState();
}

class _AddExpenseWithCategoryScreenState extends State<AddExpenseWithCategoryScreen> {
  final TextEditingController _titleController = TextEditingController(); // NOVO
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<ExpenseCategory> _basic_categories = [...ExpenseCategory.standardCategories];
  final List<ExpenseCategory> _custom_categories = [];
  ExpenseCategory? _selectedCategory;

  void _addCategory(ExpenseCategory category) {
    setState(() {
      _basic_categories.add(category);
      _selectedCategory = category;
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    IconData? selectedIcon;
    final icons = [
      Icons.fastfood, Icons.home, Icons.directions_car, Icons.sports_esports,
      Icons.shopping_cart, Icons.local_hospital, Icons.school
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nova categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: icons.map((icon) => GestureDetector(
                  onTap: () {
                    setStateDialog(() {
                      selectedIcon = icon;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedIcon == icon ? Colors.teal : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, size: 32),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedIcon != null) {
                  _addCategory(ExpenseCategory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text, icon: selectedIcon!));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A8782);

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(label: 'Título', hint: 'Descrição do gasto', controller: _titleController), // NOVO
            const SizedBox(height: 16),
            _buildTextField(label: 'Valor', hint: '0,00', controller: _valueController),
            const SizedBox(height: 16),
            _buildCategorySelector(context),
            const SizedBox(height: 16),
            _buildTextField(label: 'Nota', hint: 'Adicionar nota', controller: _noteController, maxLines: 3),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode salvar o gasto, incluindo o título
                // Remova ou comente a linha abaixo:
                // Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Salvar gasto', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: _selectedCategory,
          items: [
            ..._basic_categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Icon(cat.icon, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(cat.name),
                ],
              ),
            )),
            DropdownMenuItem(
              value: null,
              child: Row(
                children: const [
                  Icon(Icons.add, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Nova categoria'),
                ],
              ),
            ),
          ],
          onChanged: (cat) {
            if (cat == null) {
              _showAddCategoryDialog(context);
            } else {
              setState(() {
                _selectedCategory = cat;
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}