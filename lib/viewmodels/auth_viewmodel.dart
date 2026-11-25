import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth) {
    _assinatura = _auth.uidStream.listen((uid) {
      _uid = uid;
      _inicializando = false;
      notifyListeners();
    });
  }

  final AuthService _auth;
  late final StreamSubscription<String?> _assinatura;

  bool _inicializando = true;
  bool _ocupado = false;
  String? _uid;
  String? _erro;

  /// Verdadeiro até a sessão salva ser verificada.
  bool get inicializando => _inicializando;
  bool get ocupado => _ocupado;
  String? get uid => _uid;
  String? get erro => _erro;

  Future<void> entrar(String email, String senha) =>
      _executar(() => _auth.entrar(email.trim(), senha));

  Future<void> cadastrar(String email, String senha) =>
      _executar(() => _auth.cadastrar(email.trim(), senha));

  Future<void> sair() => _executar(_auth.sair);

  Future<void> _executar(Future<void> Function() acao) async {
    _ocupado = true;
    _erro = null;
    notifyListeners();
    try {
      await acao();
    } on AuthFalha catch (falha) {
      _erro = falha.mensagem;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _assinatura.cancel();
    super.dispose();
  }
}
