import 'package:firebase_auth/firebase_auth.dart';

/// Falha de autenticação já traduzida para o usuário.
class AuthFalha implements Exception {
  const AuthFalha(this.mensagem);
  final String mensagem;

  @override
  String toString() => 'AuthFalha: $mensagem';
}

abstract class AuthService {
  /// Emite o UID atual e cada mudança de sessão (null = sem sessão).
  Stream<String?> get uidStream;
  String? get uidAtual;
  Future<void> entrar(String email, String senha);
  Future<void> cadastrar(String email, String senha);
  Future<void> sair();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<String?> get uidStream =>
      _auth.authStateChanges().map((usuario) => usuario?.uid);

  @override
  String? get uidAtual => _auth.currentUser?.uid;

  @override
  Future<void> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthFalha(_mensagem(e.code));
    }
  }

  @override
  Future<void> cadastrar(String email, String senha) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFalha(_mensagem(e.code));
    }
  }

  @override
  Future<void> sair() => _auth.signOut();

  String _mensagem(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Sem conexão. Tente novamente.';
      default:
        return 'Não foi possível autenticar. Tente novamente.';
    }
  }
}
