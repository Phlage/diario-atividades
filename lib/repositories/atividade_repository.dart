import '../models/atividade.dart';
import '../services/atividade_service.dart';
import '../services/auth_service.dart';

class NaoAutenticado implements Exception {}

/// Liga as atividades ao usuário da sessão: o UID nunca vem da interface.
class AtividadeRepository {
  AtividadeRepository(this._auth, this._service);

  final AuthService _auth;
  final AtividadeService _service;

  String get _uid => _auth.uidAtual ?? (throw NaoAutenticado());

  Stream<List<Atividade>> observar() => _service.observar(_uid);

  Future<void> salvar(Atividade atividade) => atividade.id == null
      ? _service.criar(_uid, atividade)
      : _service.atualizar(_uid, atividade);

  Future<void> remover(String id) => _service.remover(_uid, id);
}
