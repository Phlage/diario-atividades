import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/atividade.dart';
import '../repositories/atividade_repository.dart';

enum EstadoLista { carregando, sucesso, vazio, erro }

class AtividadesViewModel extends ChangeNotifier {
  AtividadesViewModel(this._repositorio);

  final AtividadeRepository _repositorio;
  StreamSubscription<List<Atividade>>? _assinatura;
  bool _descartado = false;

  EstadoLista _estado = EstadoLista.carregando;
  List<Atividade> _atividades = const [];
  String? _mensagemErro;

  EstadoLista get estado => _estado;
  List<Atividade> get atividades => _atividades;
  String? get mensagemErro => _mensagemErro;

  double get totalKm => _atividades.fold<double>(
      0, (soma, atividade) => soma + atividade.distanciaKm);

  /// Começa (ou recomeça) a observar as atividades do usuário.
  void iniciar() {
    _assinatura?.cancel();
    _estado = EstadoLista.carregando;
    _mensagemErro = null;
    _avisar();
    try {
      _assinatura = _repositorio.observar().listen(
        (lista) {
          _atividades = lista;
          _estado = lista.isEmpty ? EstadoLista.vazio : EstadoLista.sucesso;
          _avisar();
        },
        onError: (Object _) => _falhar(),
      );
    } catch (_) {
      _falhar();
    }
  }

  /// Ação de recuperação da tela de erro.
  void tentarNovamente() => iniciar();

  Future<bool> salvar(Atividade atividade) async {
    try {
      await _repositorio.salvar(atividade);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remover(String id) async {
    try {
      await _repositorio.remover(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _falhar() {
    _estado = EstadoLista.erro;
    _mensagemErro = 'Não foi possível carregar suas atividades.';
    _avisar();
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _assinatura?.cancel();
    super.dispose();
  }
}
