import 'package:family_finances/styles/app_colors.dart';
import 'package:family_finances/styles/section_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/finance_state.dart';
import '../models/expense_category.dart';
import '../models/expense.dart';
import '../models/receipt.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _installmentCountController = TextEditingController();
  bool _isInInstallments = false;
  DateTime _selectedDate = DateTime.now();

  bool _isExpense = true;
  bool _validateValue() => double.tryParse(_valueController.text.replaceAll(',', '.')) != null;
  List<ExpenseCategory> _categories = [
    ExpenseCategory(name: 'Comida', icon: Icons.fastfood),
    ExpenseCategory(name: 'Moradia', icon: Icons.home),
    ExpenseCategory(name: 'Transporte', icon: Icons.directions_car),
    ExpenseCategory(name: 'Lazer', icon: Icons.sports_esports),
  ];

  ExpenseCategory? _selectedCategory;

  void _addCategory(ExpenseCategory category) {
    setState(() {
      _categories.add(category);
      _selectedCategory = category;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2A8782);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Gasto'),
                    selected: _isExpense,
                    onSelected: (selected) {
                      setState(() => _isExpense = true);
                    },
                    selectedColor: Colors.red.shade100,
                  ),
                  ChoiceChip(
                    label: const Text('Ganho'),
                    selected: !_isExpense,
                    onSelected: (selected) {
                      setState(() => _isExpense = false);
                    },
                    selectedColor: Colors.green.shade100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(label: 'Título', hint: _isExpense ? 'Título da despesa' : 'Título do ganho', controller: _titleController),
            const SizedBox(height: 16),
            _buildTextField(label: 'Valor', hint: '0,00', controller: _valueController),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(value: _isInInstallments, onChanged: (value) {
              setState(() {
                _isInInstallments = value ?? false;
              });
            }),
            const Text('Parcelado'),
              ],
            ),
            if (_isInInstallments) _buildInstallmentsCard(),
            if (_isExpense) _buildCategorySelector(context),
            if (_isExpense) const SizedBox(height: 16),
            if (_isExpense) _buildTextField(label: 'Nota', hint: 'Adicionar nota', controller: _noteController, maxLines: 3),
            const SizedBox(height: 16),
            _buildDatePicker(context),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _valueController.text.isNotEmpty &&
                    (_isExpense ? _selectedCategory != null : true)) {
                  if (_isExpense) {
                    final expense = Expense(
                      title: _titleController.text,
                      value: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0,
                      category: _selectedCategory!,
                      note: _noteController.text,
                      date: _selectedDate,
                      isInInstallments: _isInInstallments,
                      installmentCount: _isInInstallments ? int.tryParse(_installmentCountController.text) : null,
                    );
                    Provider.of<FinanceState>(context, listen: false).addExpense(expense);
                  } else {
                    final receipt = Receipt(
                      title: _titleController.text,
                      value: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0,
                      date: _selectedDate,
                    );
                    Provider.of<FinanceState>(context, listen: false).addReceipt(receipt);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isExpense ? 'Despesa salva!' : 'Receita salva!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isExpense ? 'Salvar despesa' : 'Salvar receita', style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16),
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
          value: _selectedCategory,
          items: [
            ..._categories.map((cat) => DropdownMenuItem(
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

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
    IconData? _selectedIcon;
    final icons = [Icons.fastfood, Icons.home, Icons.directions_car, Icons.sports_esports, Icons.shopping_cart, Icons.local_hospital, Icons.school];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: icons.map((icon) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon ? Colors.teal : Colors.transparent,
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
              if (_nameController.text.isNotEmpty && _selectedIcon != null) {
                _addCategory(ExpenseCategory(name: _nameController.text, icon: _selectedIcon!));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20),
        const SizedBox(width: 8),
        Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: const Text('Alterar'),
        ),
      ],
    );
  }

  Widget _buildInstallmentsCard(){
  if(!_validateValue()) return Container( decoration: SectionStyle(),padding: EdgeInsets.all(20) ,child: Text("Valor inválido!", style: TextStyle(color: AppColors.error, fontSize: 20),));
  return Container(
    decoration: SectionStyle(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    
      children: [
        Column(
          children: [
            Text('Número de parcelas')
          ],
        ),
        Column(
          children: [
            Text('Valor da parcela')
          ],
        )
      ],
    ),
  );
}
}

