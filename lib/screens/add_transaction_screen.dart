import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamp
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:family_finances/styles/app_colors.dart';
import 'package:family_finances/styles/section_style.dart';

import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/expense_category.dart';
import '../models/receipt_category.dart';

// Imports dos Produtos
import '../models/product.dart';
import '../models/product_option.dart';
import '../models/product_category.dart';

import 'qr_code_scanner_screen.dart';
import '../services/nfce_service.dart';

enum RecurrencyType { monthly, weekly, custom }

class AddTransactionScreen extends StatefulWidget {
  final Expense? expenseToEdit;
  final Receipt? receiptToEdit;

  const AddTransactionScreen({
    super.key,
    this.expenseToEdit,
    this.receiptToEdit,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _intervalController = TextEditingController();
  final _installmentValueController = TextEditingController();

  bool _isExpense = true;
  bool _isInInstallments = false;
  bool _isRecurrent = false;
  bool _isShared = false;
  
  bool _isLoadingNfce = false;
  
  // Lista para armazenar os produtos
  List<Product> _importedProducts = [];

  RecurrencyType? _recurrencyType;
  DateTime _selectedDate = DateTime.now();

  int _selectedDayOfMonth = DateTime.now().day;
  int _selectedDayOfWeek = DateTime.now().weekday;

  ExpenseCategory? _selectedCategory;

  final List<ExpenseCategory> _categories = [
    ExpenseCategory(name: "Comida", icon: Icons.fastfood),
    ExpenseCategory(name: "Moradia", icon: Icons.home),
    ExpenseCategory(name: "Transporte", icon: Icons.directions_car),
    ExpenseCategory(name: "Lazer", icon: Icons.sports_esports),
    ExpenseCategory(name: "Compras", icon: Icons.shopping_cart),
    ExpenseCategory(name: "Saúde", icon: Icons.local_hospital),
    ExpenseCategory(name: "Educação", icon: Icons.school),
    ExpenseCategory(name: "Outros", icon: Icons.category),
  ];

  @override
  void initState() {
    super.initState();

    _valueController.addListener(_updateInstallmentValue);
    _installmentCountController.addListener(_updateInstallmentValue);

    // PRÉ-PREENCHIMENTO EM MODO EDIÇÃO
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;

      _isExpense = true;
      _titleController.text = e.title;
      _valueController.text = e.value.toString();
      _noteController.text = e.note;
      _selectedCategory = e.category;
      _selectedDate = e.date;

      // --- CORREÇÃO AQUI: Carregar produtos existentes ---
      if (e.items.isNotEmpty) {
        _importedProducts = List.from(e.items);
      }
      // ---------------------------------------------------

      _isInInstallments = e.isInInstallments;
      if (_isInInstallments) {
        _installmentCountController.text = e.installmentCount?.toString() ?? "1";
      }

      _isRecurrent = e.isRecurrent;
      if (_isRecurrent) {
        _recurrencyType = RecurrencyType.values[e.recurrencyType!];
        if (_recurrencyType == RecurrencyType.custom) {
          _intervalController.text = e.recurrentIntervalDays?.toString() ?? "";
        }
      }

      _isShared = e.isShared;
    } else if (widget.receiptToEdit != null) {
      final r = widget.receiptToEdit!;
      _isExpense = false;
      _titleController.text = r.title;
      _valueController.text = r.value.toString();
      _selectedDate = r.date;
      _noteController.text = r.note ?? "";
      _isRecurrent = r.isRecurrent;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    _installmentValueController.dispose();
    _intervalController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _updateInstallmentValue() {
    final total = double.tryParse(_valueController.text.replaceAll(",", ".")) ?? 0;
    final count = int.tryParse(_installmentCountController.text) ?? 1;

    final result = count > 0 ? (total / count) : 0;
    _installmentValueController.text = result.toStringAsFixed(2);
    if (mounted) setState(() {});
  }

  Future<void> _scanAndLoadNfce() async {
    final String? url = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRCodeScannerScreen()),
    );

    if (url == null || url.isEmpty) return;

    setState(() {
      _isLoadingNfce = true;
      _importedProducts = []; // Limpa lista ao escanear nova nota
    });

    try {
      final nfceService = NfceService();
      final nfceData = await nfceService.fetchAndParseNfce(url);

      final defaultProductCategory = ProductCategory.indefinida;

      final List<Product> productsFromNote = nfceData.items.map((item) {
        return Product(
          name: item.name,
          category: defaultProductCategory,
          isChecked: false,
          options: [
            ProductOption(
              brand: '',
              storeName: nfceData.storeName,
              price: item.unitPrice,
              quantity: item.quantity.toString(),
              purchaseDate: nfceData.date,
            )
          ],
        );
      }).toList();

      setState(() {
        _titleController.text = nfceData.storeName;
        _valueController.text = nfceData.totalValue.toStringAsFixed(2);
        _selectedDate = nfceData.date.toDate();
        _importedProducts = productsFromNote;
        
        if (_selectedCategory == null) {
             final lowerName = nfceData.storeName.toLowerCase();
             if (lowerName.contains("mercado") || lowerName.contains("atacad") || lowerName.contains("super")) {
                _selectedCategory = _categories.firstWhere((c) => c.name == "Compras", orElse: () => _categories.last);
             } else if (lowerName.contains("restaurante") || lowerName.contains("lanchonete")) {
                _selectedCategory = _categories.firstWhere((c) => c.name == "Comida", orElse: () => _categories.last);
             }
        }

        final itemsList = nfceData.items.map((i) => "- ${i.name} (${i.quantity}x)").join("\n");
        _noteController.text = "Importado via NFC-e.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nota importada com sucesso!")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao ler nota: $e")),
      );
    } finally {
      setState(() {
        _isLoadingNfce = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceState>(context, listen: false);
    final hasPartner = finance.hasPartnership;
    _isShared = hasPartner;



    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: Text(
          widget.expenseToEdit == null && widget.receiptToEdit == null
              ? "Nova Transação"
              : "Editar Transação",
        ),
      ),

      body: _isLoadingNfce 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Importando dados da nota fiscal..."),
            ],
          ))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text("Despesa"),
                    selected: _isExpense,
                    selectedColor: Colors.red.shade200,
                    onSelected: (_) => setState(() => _isExpense = true),
                  ),

                  ChoiceChip(
                    label: const Text("Receita"),
                    selected: !_isExpense,
                    selectedColor: Colors.green.shade200,
                    onSelected: (_) => setState(() => _isExpense = false),
                  ),

                  if (hasPartner)
                    ChoiceChip(
                      label: Text(_isShared ? "Compartilhado" : "Privado"),
                      selected: _isShared,
                      selectedColor: Colors.blue.shade200,
                      onSelected: (_) => setState(() => _isShared = !_isShared),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_isExpense) 
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _scanAndLoadNfce,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Ler NFC-e (QR Code)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

            _buildInput("Título", "Ex: Mercado", _titleController),
            const SizedBox(height: 16),
            _buildInput("Valor", "0,00", _valueController, keyboard: TextInputType.number),

            // LISTA DE PRODUTOS IMPORTADOS
            if (_importedProducts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Produtos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${_importedProducts.length} itens", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              _buildImportedProductsList(),
            ],

            const SizedBox(height: 20),

            _buildSwitchRow(),

            if (_isInInstallments) _buildInstallmentsCard(),
            if (_isRecurrent) _buildRecurrencyCard(),

            if (_isExpense) const SizedBox(height: 16),
            if (_isExpense) _buildCategorySelector(),

            const SizedBox(height: 16),
            _buildInput("Nota (opcional)", "Adicionar nota...", _noteController, maxLines: 3),

            const SizedBox(height: 20),
            _buildDatePicker(),

            const SizedBox(height: 40),
            _buildSaveButton(finance),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedProductsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _importedProducts.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final product = _importedProducts[i];
          final double price = product.options.isNotEmpty ? product.options.first.price : 0.0;
          
          return ListTile(
            dense: true,
            leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
            title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              "R\$ ${price.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput(
    String label,
    String hint,
    TextEditingController controller, {int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow() {
    return Row(
      children: [
        Checkbox(
          value: _isInInstallments,
          onChanged: (v) {
            setState(() {
              _isInInstallments = v ?? false;
              if (_isInInstallments) _isRecurrent = false;
            });
          },
        ),
        const Text("Parcelado"),

        const SizedBox(width: 24),

        Checkbox(
          value: _isRecurrent,
          onChanged: (v) {
            setState(() {
              _isRecurrent = v ?? false;
              if (_isRecurrent) _isInInstallments = false;
            });
          },
        ),
        const Text("Recorrente"),
      ],
    );
  }

  Widget _buildInstallmentsCard() {
    final total = double.tryParse(_valueController.text.replaceAll(",", ".")) ?? 0;
    final count = int.tryParse(_installmentCountController.text) ?? 1;
    final installment = count > 0 ? total / count : 0;

    return Container(
      decoration: SectionStyle(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text("Parcelas"),
                const SizedBox(height: 6),
                TextField(
                  controller: _installmentCountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                const Text("Valor da parcela"),
                const SizedBox(height: 6),
                Text(
                  "R\$ ${installment.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecurrencyCard() {
    return Container(
      decoration: SectionStyle(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tipo de Recorrência", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text("Mensal"),
                selected: _recurrencyType == RecurrencyType.monthly,
                onSelected: (_) => setState(() => _recurrencyType = RecurrencyType.monthly),
              ),
              ChoiceChip(
                label: const Text("Semanal"),
                selected: _recurrencyType == RecurrencyType.weekly,
                onSelected: (_) => setState(() => _recurrencyType = RecurrencyType.weekly),
              ),
              ChoiceChip(
                label: const Text("Customizado"),
                selected: _recurrencyType == RecurrencyType.custom,
                onSelected: (_) => setState(() => _recurrencyType = RecurrencyType.custom),
              ),
            ],
          ),

          if (_recurrencyType == RecurrencyType.monthly)
            _buildDaySelector("Dia do mês", 31, _selectedDayOfMonth,
                (v) => setState(() => _selectedDayOfMonth = v)),

          if (_recurrencyType == RecurrencyType.weekly)
            _buildDaySelector("Dia da semana", 7, _selectedDayOfWeek,
                (v) => setState(() => _selectedDayOfWeek = v)),

          if (_recurrencyType == RecurrencyType.custom)
            _buildInput("Intervalo (dias)", "30", _intervalController),
        ],
      ),
    );
  }

  Widget _buildDaySelector(
      String label, int max, int current, Function(int) onChange) {
    final days = List.generate(max, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: current,
          items: days.map((d) {
            return DropdownMenuItem(
              value: d,
              child: Text(max == 7
                  ? ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"][d - 1]
                  : d.toString()),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (v) => onChange(v!),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedCategory,
      items: _categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(cat.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (cat) => setState(() => _selectedCategory = cat),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: const Text("Selecione a categoria"),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 20),
        const SizedBox(width: 10),
        Text("Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(2010),
              lastDate: DateTime(2100),
              initialDate: _selectedDate,
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: const Text("Alterar"),
        )
      ],
    );
  }

  Widget _buildSaveButton(FinanceState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          if (_titleController.text.isEmpty ||
              _valueController.text.isEmpty ||
              (_isExpense && _selectedCategory == null)) {
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Preencha os campos obrigatórios (Título, Valor, Categoria)")),
            );
            return;
          }

          final value = double.tryParse(_valueController.text.replaceAll(",", ".")) ?? 0;

          if (_isExpense) {
            final exp = Expense(
              id: widget.expenseToEdit?.id,
              title: _titleController.text,
              value: value,
              note: _noteController.text,
              category: _selectedCategory!,
              date: _selectedDate,
              isInInstallments: _isInInstallments,
              installmentCount: _isInInstallments
                  ? int.tryParse(_installmentCountController.text)
                  : null,
              isRecurrent: _isRecurrent,
              recurrencyType: _recurrencyType?.index,
              recurrentIntervalDays: _recurrencyType == RecurrencyType.custom
                  ? int.tryParse(_intervalController.text)
                  : null,
              isShared: _isShared,
              recurrencyId: widget.expenseToEdit?.recurrencyId,
              // Passa a lista de produtos (que agora já vem preenchida no initState)
              items: _importedProducts,
            );

            widget.expenseToEdit == null
                ? await state.addExpense(exp)
                : await state.updateExpense(exp);
          } else {
            final rec = Receipt(
              id: widget.receiptToEdit?.id,
              title: _titleController.text,
              value: value,
              category: ReceiptCategory(name: "Outros", icon: Icons.category),
              note: _noteController.text,
              date: _selectedDate,
              isRecurrent: _isRecurrent,
              recurrencyType: _recurrencyType?.index,
              isShared: _isShared,
            );

            widget.receiptToEdit == null
                ? await state.addReceipt(rec)
                : await state.updateReceipt(rec);
          }

          if (mounted) Navigator.pop(context);
        },
        child: const Text("Salvar", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}