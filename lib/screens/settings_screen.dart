import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para o Clipboard
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 1. Import para gerar QR

import '../models/finance_state.dart';
import 'auth_gate.dart';
import '../styles/app_colors.dart';
import 'qr_code_scanner_screen.dart'; // 2. Import para ler QR

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _partnerIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _partnerIdController.dispose();
    super.dispose();
  }

  // ==============================================================================
  // LÓGICA DE PAREAMENTO
  // ==============================================================================
  Future<void> _pairWithUser(String myUid, String partnerUid) async {
    if (partnerUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira o código do parceiro')),
      );
      return;
    }

    if (myUid == partnerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não pode parear consigo mesmo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gera um ID único para a coleção compartilhada
      final String sharedCollectionId = "${myUid}_${partnerUid}_shared";

      final batch = FirebaseFirestore.instance.batch();

      // 1. Define o vínculo para o MEU usuário
      final myDocRef = FirebaseFirestore.instance.collection('partnerships').doc(myUid);
      batch.set(myDocRef, {
        'partnerId': partnerUid,
        'sharedCollectionId': sharedCollectionId,
        'connectedAt': FieldValue.serverTimestamp(),
      });

      // 2. Define o vínculo para o usuário PARCEIRO
      final partnerDocRef = FirebaseFirestore.instance.collection('partnerships').doc(partnerUid);
      batch.set(partnerDocRef, {
        'partnerId': myUid,
        'sharedCollectionId': sharedCollectionId,
        'connectedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta vinculada com sucesso!')),
      );
      _partnerIdController.clear();
      
      if (mounted) {
        Provider.of<FinanceState>(context, listen: false).forceNotify();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao vincular: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unpairUser(String myUid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Desconectar?"),
        content: const Text(
            "Isso removerá o acesso aos dados compartilhados. Os dados não serão apagados, apenas o vínculo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Desconectar")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final myDocSnap = await FirebaseFirestore.instance.collection('partnerships').doc(myUid).get();
      
      if (myDocSnap.exists) {
        final data = myDocSnap.data();
        final partnerId = data?['partnerId'];

        final batch = FirebaseFirestore.instance.batch();
        batch.delete(FirebaseFirestore.instance.collection('partnerships').doc(myUid));

        if (partnerId != null) {
          batch.delete(FirebaseFirestore.instance.collection('partnerships').doc(partnerId));
        }

        await batch.commit();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vínculo removido.')),
      );

      if (mounted) {
        Provider.of<FinanceState>(context, listen: false).forceNotify();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao desconectar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!'), duration: Duration(seconds: 1)),
    );
  }

  // NOVO: Função para ler QR Code do parceiro
  Future<void> _scanPartnerQrCode() async {
    final String? code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRCodeScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      setState(() {
        _partnerIdController.text = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código lido com sucesso!')),
      );
    }
  }

  // NOVO: Modal para exibir meu QR Code
  void _showMyQrCode(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text("Seu Código QR")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: QrImageView(
                data: uid,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Peça para seu parceiro escanear este código no app dele.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // UI
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FinanceState>(context);
    final user = FirebaseAuth.instance.currentUser;
    final hasPartnership = state.hasPartnership;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------------------------------------
          // PERFIL
          // -------------------------------------------------------
          if (user != null)
            _buildSectionCard(
              title: "Perfil",
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(user.email ?? 'Usuário sem email'),
                  subtitle: const Text('Conta logada'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      state.forceNotify();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthGate()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da Conta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // -------------------------------------------------------
          // PAREAMENTO FAMILIAR
          // -------------------------------------------------------
          if (user != null)
            _buildSectionCard(
              title: "Pareamento Familiar",
              children: [
                if (hasPartnership) ...[
                  // ESTADO: PAREADO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade50,
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          "Você está conectado!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID Parceiro: ${state.currentPartnerId}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _unpairUser(user.uid),
                      icon: const Icon(Icons.link_off),
                      label: const Text("Desconectar Parceria"),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ] else ...[
                  // ESTADO: NÃO PAREADO
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      "Conecte-se com seu cônjuge ou familiar para gerenciar as finanças juntos.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  
                  // Mostrar Meu Código
                  ListTile(
                    title: const Text("Seu Código"),
                    subtitle: Text(
                      user.uid,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão para mostrar QR
                        IconButton(
                          icon: const Icon(Icons.qr_code),
                          tooltip: "Mostrar QR Code",
                          onPressed: () => _showMyQrCode(context, user.uid),
                        ),
                        // Botão de Copiar
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: "Copiar ID",
                          onPressed: () => _copyToClipboard(user.uid),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Inserir Código do Parceiro
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _partnerIdController,
                          decoration: InputDecoration(
                            labelText: "Código do Parceiro",
                            hintText: "Cole ou escaneie",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.link),
                            // Botão para abrir scanner
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanPartnerQrCode,
                              tooltip: "Ler QR Code",
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _pairWithUser(user.uid, _partnerIdController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Conectar"),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

          if (user == null)
            _buildSectionCard(
              title: "Acesso",
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Faça login para salvar seus dados na nuvem e compartilhar com a família."),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                      );
                    },
                    child: const Text('Login / Criar Conta'),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 20),

          // -------------------------------------------------------
          // DEBUG / OUTROS
          // -------------------------------------------------------
          _buildSectionCard(
            title: "Sistema",
            children: [
              ListTile(
                title: const Text("Recarregar dados"),
                subtitle: const Text("Forçar sincronização"),
                trailing: const Icon(Icons.refresh),
                onTap: () {
                  state.forceNotify();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estado atualizado')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}