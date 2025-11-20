import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../models/receipt_category.dart';

class CategoryPicker extends StatelessWidget {
  final bool isExpense;

  final ExpenseCategory? selectedExpense;
  final ReceiptCategory? selectedReceipt;

  const CategoryPicker({
    super.key,
    required this.isExpense,
    this.selectedExpense,
    this.selectedReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> categories = isExpense
        ? ExpenseCategory.defaults
        : ReceiptCategory.defaults;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Escolher categoria",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: .8,
                ),
                itemBuilder: (_, i) {
                  final cat = categories[i];

                  final bool isSelected = isExpense
                      ? selectedExpense?.name == cat.name
                      : selectedReceipt?.name == cat.name;

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, cat),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: isSelected ? 28 : 24,
                          backgroundColor: isSelected
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                          child: Icon(
                            cat.icon,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
