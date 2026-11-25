import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/atividade_repository.dart';
import 'repositories/clima_repository.dart';
import 'services/atividade_service.dart';
import 'services/auth_service.dart';
import 'services/localizacao_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth_gate.dart';

/// Raiz do app. Recebe os serviços por parâmetro para que os testes
/// possam trocar Firebase, rede e localização por dublês.
class DiarioApp extends StatelessWidget {
  const DiarioApp({
    super.key,
    required this.auth,
    required this.atividades,
    required this.clima,
    required this.localizacao,
  });

  final AuthService auth;
  final AtividadeService atividades;
  final ClimaRepository clima;
  final LocalizacaoService localizacao;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ClimaRepository>.value(value: clima),
        Provider<LocalizacaoService>.value(value: localizacao),
        Provider<AtividadeRepository>(
          create: (_) => AtividadeRepository(auth, atividades),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Diário de Atividades',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}
