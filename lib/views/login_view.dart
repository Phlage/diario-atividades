import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _enviar({required bool cadastro}) {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    if (cadastro) {
      auth.cadastrar(_email.text, _senha.text);
    } else {
      auth.entrar(_email.text, _senha.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.directions_run,
                    size: 64,
                    color: tema.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diário de Atividades',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('campoEmail'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) =>
                        (valor == null || !valor.contains('@'))
                            ? 'Informe um e-mail válido.'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('campoSenha'),
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) => (valor == null || valor.length < 6)
                        ? 'A senha precisa ter pelo menos 6 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (auth.erro != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        auth.erro!,
                        key: const Key('erroLogin'),
                        style: TextStyle(color: tema.colorScheme.error),
                      ),
                    ),
                  if (auth.ocupado)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    FilledButton(
                      key: const Key('botaoEntrar'),
                      onPressed: () => _enviar(cadastro: false),
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('botaoCadastrar'),
                      onPressed: () => _enviar(cadastro: true),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
