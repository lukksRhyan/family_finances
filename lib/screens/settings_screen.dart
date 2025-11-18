  import 'package:family_finances/models/partnership.dart';
  import 'package:family_finances/models/product_category.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'dart:convert';
  import 'dart:io';
  import 'package:path_provider/path_provider.dart';
  import 'package:file_picker/file_picker.dart';
  import 'package:intl/intl.dart'; 
  import 'package:family_finances/screens/auth_gate.dart';
  import '../models/finance_state.dart';
  import '../models/expense.dart';
  import '../models/receipt.dart';
  import '../models/product.dart'; 

  class SettingsScreen extends StatelessWidget {
    const SettingsScreen({super.key});

    Future<void> _exportData(BuildContext context) async {
      final state = Provider.of<FinanceState>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não logado.')));
        return;
      }

      // Exporta apenas os dados privados e compartilhados (que já estão no state)
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

    Future<void> _importData(BuildContext context) async {
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
                final newExpense = Expense.fromMapFromFirestore(eMap..['id'] = null, '');
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
            content: Text('Importação concluída: ${importedExpenses}E/${importedReceipts}R/${importedProducts}P novos. ${skippedExpenses}E/${skippedReceipts}R/${importedProducts}P ignorados (duplicados/erro).'),
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

    // NOVO: UI para enviar convite
    void _showSendInviteDialog(BuildContext context) {
      final TextEditingController emailController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Convidar Parceiro'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'UID ou Email do Parceiro'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final partnerIdentifier = emailController.text.trim();
                if (partnerIdentifier.isNotEmpty) {
                  Navigator.of(ctx).pop(); // Fecha o diálogo
                  try {
                    // O parceiro pode inserir o UID ou o email (para simplificar o teste)
                    await Provider.of<FinanceState>(context, listen: false).sendInvite(partnerIdentifier);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convite enviado!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar convite: ${e.toString()}'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Enviar Convite'),
            ),
          ],
        )
      );
    }

    // NOVO: UI para aceitar convite
    void _handleAcceptInvite(BuildContext context, PartnershipInvite invite) async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await Provider.of<FinanceState>(context, listen: false).acceptInvite(invite);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parceria estabelecida com sucesso!')));
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao aceitar parceria: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }

    // NOVO: UI para remover parceria
    void _confirmRemovePartnership(BuildContext context) {
      final financeState = Provider.of<FinanceState>(context, listen: false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: const Text('Tem certeza que deseja terminar a parceria? As transações conjuntas não serão removidas do histórico de transações conjuntas.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await financeState.removePartnership();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parceria terminada.')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao terminar parceria: ${e.toString()}'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Terminar Parceria', style: TextStyle(color: Colors.red)),
            ),
          ],
        )
      );
    }

    @override
    Widget build(BuildContext context) {
      final financeState = Provider.of<FinanceState>(context);
      final bool isLoggedIn = financeState.isLoggedIn;
      final user = FirebaseAuth.instance.currentUser;
      final String? currentPartnerId = financeState.currentPartnerId;
      final List<PartnershipInvite> incomingInvites = financeState.incomingInvites;

      return Scaffold(
        appBar: AppBar(title: const Text('Configurações e Backup')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Seção de Parceria ---
              Text('Parceria de Contas (Compartilhamento)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              if (!isLoggedIn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text('Faça login para gerenciar a parceria.', style: TextStyle(color: Colors.red)),
                ),
              
              // Gerenciamento de Parceria
              if (isLoggedIn) ...[
                if (currentPartnerId != null) ...[
                  // Parceria Ativa
                  Card(
                    color: Colors.lightGreen.shade50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Parceria Ativa:', style: TextStyle(fontWeight: FontWeight.bold)),
                          // Exibe o UID do parceiro (aqui com substring para não poluir demais)
                          Text('UID do Parceiro: ${currentPartnerId.length > 8 ? '${currentPartnerId.substring(0, 8)}...' : currentPartnerId}'),
                          const SizedBox(height: 8),
                          Text('Transações conjuntas salvas em: ${financeState.sharedCollectionId}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Terminar Parceria'),
                            onPressed: () => _confirmRemovePartnership(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (incomingInvites.isNotEmpty) ...[
                  // Convites Pendentes
                  // CORREÇÃO APLICADA AQUI: Removido o list wrapper desnecessário e o .expand/.toList()
                  ...incomingInvites.map((invite) => Card(
                    color: Colors.yellow.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: const Text('Convite de Parceria Recebido'),
                      subtitle: Text('De: ${invite.senderId.length > 8 ? '${invite.senderId.substring(0, 8)}...' : invite.senderId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _handleAcceptInvite(context, invite),
                          ),
                            IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => financeState.declineInvite(invite.id),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ] else ...[
                  // Sem Parceria
                  const Text('Você não tem uma parceria ativa.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Convidar Novo Parceiro'),
                    onPressed: () => _showSendInviteDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 32),
              // --- Seção de Backup ---
              Text('Backup e Restauração', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Exportar Backup (JSON)'),
                onPressed: isLoggedIn ? () => _exportData(context) : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Importar Backup (JSON)'),
                onPressed: isLoggedIn ? () => _importData(context) : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
              
              const SizedBox(height: 32),
              // --- Seção de Conta ---
              Text('Conta', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              if (isLoggedIn) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      user?.email ?? 'Logado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da Conta'),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar Saída'),
                        content: const Text('Tem certeza que deseja sair? Os seus dados locais serão apagados e os dados da nuvem serão carregados no próximo login.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await FirebaseAuth.instance.signOut();
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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              const SizedBox(height: 32),
              //),
              const Center(child: Text('Versão 1.0.0 (híbrida)')),
            ],
          ),
        ),
      );
    }
  }