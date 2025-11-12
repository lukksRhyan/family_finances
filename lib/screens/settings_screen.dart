import 'package:family_finances/models/product_category.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; 
// Importa o AuthGate para podermos navegar de volta para ele
import 'package:family_finances/screens/auth_gate.dart';
import '../models/finance_state.dart';
import '../models/expense.dart';
import '../models/receipt.dart';
import '../models/product.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // A função _exportData permanece a mesma
  Future<void> _exportData(BuildContext context) async {
// ... (código existente, não precisa de alterações) ...
    final state = Provider.of<FinanceState>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não logado.')));
       return;
    }

    final data = {
      'expenses': state.expenses.map((e) => e.toMapForFirestore()).toList(),
      'receipts': state.receipts.map((r) => r.toMapForFirestore()).toList(),
      'products': state.shoppingListProducts.map((p) => p.toMapForFirestore()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

     try {
       String fileName = 'family_finances_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
       String? outputFile;

       if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
         outputFile = await FilePicker.platform.saveFile(
           dialogTitle: 'Salvar backup como...',
           fileName: fileName,
           allowedExtensions: ['json'],
           type: FileType.custom,
         );
       } else {
          final directory = await getApplicationDocumentsDirectory();
          outputFile = '${directory.path}/$fileName';
       }


       if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(jsonStr);
          if(context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Backup salvo em: ${file.path}')),
            );
          }
       } else {
         if(context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exportação cancelada.')),
            );
         }
       }
     } catch (e) {
        print("Erro ao exportar dados: $e");
        if(context.mounted){
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao exportar dados: $e'), backgroundColor: Colors.red),
           );
        }
     }
  }

  // A função _importData permanece a mesma
  Future<void> _importData(BuildContext context) async {
// ... (código existente, não precisa de alterações) ...
    final user = FirebaseAuth.instance.currentUser;
     if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não logado.')));
       return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum arquivo selecionado')),
      );
      return;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);

    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de importação não encontrado')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr);
      final state = Provider.of<FinanceState>(context, listen: false);

       int importedExpenses = 0;
       int importedReceipts = 0;
       int importedProducts = 0;
       int skippedExpenses = 0;
       int skippedReceipts = 0;
       int skippedProducts = 0;

      if (data['expenses'] is List) {
        for (var eMap in data['expenses']) {
          if (eMap is Map<String, dynamic>) {
            try {
              // Usa o construtor fromMapFromFirestore
              final newExpense = Expense.fromMapFromFirestore(eMap..['id'] = null, ''); // ID será gerado pelo Firestore
              bool exists = state.expenses.any((existing) =>
                existing.title == newExpense.title &&
                existing.value == newExpense.value &&
                existing.date.isAtSameMomentAs(newExpense.date)
              );
              if (!exists) {
                await state.addExpense(newExpense);
                importedExpenses++;
              } else {
                skippedExpenses++;
              }
            } catch (e) {
               print("Erro ao importar despesa: $e - Dados: $eMap");
               skippedExpenses++;
            }
          }
        }
      }

       if (data['receipts'] is List) {
         for (var rMap in data['receipts']) {
           if (rMap is Map<String, dynamic>) {
             try {
                final newReceipt = Receipt.fromMapFromFirestore(rMap..['id'] = null, '');
                bool exists = state.receipts.any((existing) =>
                  existing.title == newReceipt.title &&
                  existing.value == newReceipt.value &&
                  existing.date.isAtSameMomentAs(newReceipt.date)
                );
                if (!exists) {
                  await state.addReceipt(newReceipt);
                  importedReceipts++;
                } else {
                  skippedReceipts++;
                }
             } catch (e) {
                print("Erro ao importar receita: $e - Dados: $rMap");
                skippedReceipts++;
             }
           }
         }
       }

       if (data['products'] is List) {
         for (var pMap in data['products']) {
            if (pMap is Map<String, dynamic>) {
               try {
                 // Busca a categoria pelo ID ou usa indefinida
                 final categoryId = pMap['categoryId'] ?? ProductCategory.indefinida.id;
                 final category = state.productCategories.firstWhere(
                   (c) => c.id == categoryId, 
                   orElse: () => ProductCategory.indefinida
                 );

                 final newProduct = Product.fromMapFromFirestore(pMap..['id'] = null, '', category);

                 bool exists = state.shoppingListProducts.any((existing) =>
                   existing.nameLower == newProduct.nameLower
                 );

                 if (!exists) {
                    await state.addProduct(newProduct);
                    importedProducts++;
                 } else {
                   skippedProducts++;
                 }
               } catch (e) {
                  print("Erro ao importar produto: $e - Dados: $pMap");
                  skippedProducts++;
               }
            }
         }
       }

      Navigator.of(context).pop(); // Fecha o loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importação concluída: ${importedExpenses}E/${importedReceipts}R/${importedProducts}P novos. ${skippedExpenses}E/${skippedReceipts}R/${skippedProducts}P ignorados (duplicados/erro).'),
          duration: const Duration(seconds: 5),
       ),
      );
    } catch (e) {
        Navigator.of(context).pop(); // Fecha o loading
        print("Erro crítico ao importar dados: $e");
        if(context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao ler ou processar o arquivo de backup: $e'), backgroundColor: Colors.red),
           );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o estado de login
    final financeState = Provider.of<FinanceState>(context);
    final bool isLoggedIn = financeState.isLoggedIn;
    final user = FirebaseAuth.instance.currentUser; // Pega o utilizador atual

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações e Backup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Backup e Restauração (Requer Login)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Botão de Exportar - Desabilitado se não estiver logado
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Exportar Backup (JSON)'),
              onPressed: isLoggedIn ? () => _exportData(context) : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            // Botão de Importar - Desabilitado se não estiver logado
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Importar Backup (JSON)'),
              onPressed: isLoggedIn ? () => _importData(context) : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 32),
            Text('Conta', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // --- INÍCIO DA ALTERAÇÃO ---

            if (isLoggedIn) ...[
              // Se estiver logado, mostra o e-mail e o botão de Sair
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    user?.email ?? 'Logado', // Mostra o e-mail do utilizador
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Conta'),
                onPressed: () async {
                  // Confirmação antes de sair
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar Saída'),
                      content: const Text('Tem certeza que deseja sair? Os seus dados locais serão apagados e os dados da nuvem serão carregados no próximo login.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop(); // Fecha o diálogo
                            await FirebaseAuth.instance.signOut();
                            // O AuthGate e o FinanceState irão tratar da navegação
                            // e da limpeza dos dados automaticamente.
                          },
                          child: const Text('Sair', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // Se estiver deslogado, mostra a mensagem e o botão de Login
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Você está em modo local (convidado).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Fazer Login ou Registar'),
                onPressed: () {
                  // Navega de volta para o AuthGate, limpando a pilha de navegação
                  // O AuthGate então mostrará o LoginScreen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false, // Remove todas as rotas anteriores
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // Cor primária
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            // --- FIM DA ALTERAÇÃO ---
            
            const Spacer(),
            const Center(child: Text('Versão 1.0.0 (híbrida)')),
          ],
        ),
      ),
    );
  }
}