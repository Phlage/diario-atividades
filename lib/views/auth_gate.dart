import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/atividade_repository.dart';
import '../viewmodels/atividades_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'atividades_view.dart';
import 'login_view.dart';

/// Controla o acesso: sem sessão, só a tela de login é alcançável.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.inicializando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.uid == null) return const LoginView();

    // A chave por UID recria o ViewModel quando o usuário muda.
    return ChangeNotifierProvider<AtividadesViewModel>(
      key: ValueKey(auth.uid),
      create: (context) =>
          AtividadesViewModel(context.read<AtividadeRepository>())..iniciar(),
      child: const AtividadesView(),
    );
  }
}
