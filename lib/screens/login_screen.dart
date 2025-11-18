import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../models/finance_state.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false; // Estado de loading para a sincronização

  @override
  void initState() {
    super.initState();

    final GoogleSignIn signIn = GoogleSignIn.instance;

    // Inicialização do Google Sign In.
    // O listener abaixo lida com a autenticação e o Firebase AuthStateChanges no FinanceState
    // se encarrega de carregar/sincronizar os dados após o login bem-sucedido.
    signIn.initialize(
      clientId: null,
      serverClientId: null
    ).then((_){
        signIn.authenticationEvents.listen((event) async{
            if(event case GoogleSignInAuthenticationEventSignIn(: final user)){
              final auth = await user.authentication;
              final credential = GoogleAuthProvider.credential(
                idToken: auth.idToken,
              );
              // Faz o login no Firebase. Isso dispara o listener do FinanceState.
              await FirebaseAuth.instance.signInWithCredential(credential);
            }
        });
    });
  }


  // Função de sincronização (mantida, mas agora só é chamada se o login falhar
  // e o usuário precisar de uma retentativa de sync, embora a chamada principal
  // venha do FinanceState).
  Future<void> _syncLocalData(String newUid) async {
    final financeState = Provider.of<FinanceState>(context, listen: false);
    
    // Verifica se o utilizador estava em modo local antes de tentar sincronizar
    if (financeState.isLoggedIn) {
      return; // Já está logado, não precisa sincronizar
    }

    // VERIFICAÇÃO "MOUNTED"
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = "Sincronizando dados locais para a nuvem...";
      });
    }

    try {
      // Chamada real da sincronização
      // O AuthGate tratará da navegação após o estado de auth mudar
    } catch (e) {
      // VERIFICAÇÃO "MOUNTED"
      if (mounted) {
        setState(() {
          _errorMessage = "Erro ao sincronizar: $e. Faça login novamente mais tarde para tentar de novo.";
        });
      }
    } finally {
      // VERIFICAÇÃO "MOUNTED"
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    try {
      if (mounted) {
        setState(() {
           _isLoading = true;
           _errorMessage = null;
        });
      }
      
      // 1. Faz o login no Firebase. 
      // O listener de auth no FinanceState cuidará da sincronização e navegação
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 2. Não precisamos mais da lógica de sincronização aqui.
      // O FinanceState agora ouve a mudança de estado de autenticação e inicia a sincronização automaticamente.

    } on FirebaseAuthException catch (e) {
      if(mounted){
        setState(() {
          _isLoading = false;
          _errorMessage = e.message ?? "Ocorreu um erro.";
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    try {
      if (mounted) {
        setState(() {
           _isLoading = true;
           _errorMessage = null;
        });
      }

      // 1. Cria o utilizador no Firebase.
      // O listener de auth no FinanceState cuidará da sincronização e navegação
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // 2. Não precisamos mais da lógica de sincronização aqui.
      // O FinanceState agora ouve a mudança de estado de autenticação e inicia a sincronização automaticamente.

    } on FirebaseAuthException catch (e) {
       if(mounted){
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? "Ocorreu um erro.";
          });
       }
    }
  }
  
  Future<void> _signInWithGoogle() async {
    final signIn = GoogleSignIn.instance;

    if (!signIn.supportsAuthenticate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este dispositivo não suporta login Google nativo.")),
      );
      return;
    }

    try {
      // A chamada a authenticate() vai disparar o listener no initState
      await signIn.authenticate(); 
      // O listener de auth no FinanceState cuidará da sincronização e navegação.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao autenticar com Google: $e")),
      );
    }
  }


  void _continueAsGuest() {
    if (_isLoading) return;
    // Simplesmente navega para o MainScreen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF2A8782)),
                const SizedBox(height: 16),
                const Text(
                  'FamilyFinances',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty) ? 'Por favor, insira o email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'A senha deve ter pelo menos 6 caracteres' : null,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: _isLoading ? Colors.blue : Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),

                // Mostra um indicador de loading nos botões
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2A8782)
                    ),
                    child: const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _register,
                    style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Registar', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // NOVO BOTÃO: Continuar sem login
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: const Text(
                      'Continuar sem login',
                      style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(height: 20),
ElevatedButton.icon(
  icon: Image.asset(
    'assets/google_logo.png',
    height: 24,
  ),
  label: const Text("Continuar com Google"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Colors.grey),
    ),
  ),
  onPressed: _signInWithGoogle,
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}