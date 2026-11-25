import 'package:flutter/foundation.dart';

import '../repositories/clima_repository.dart';
import '../services/clima_service.dart';
import '../services/localizacao_service.dart';

enum EstadoClima { inicial, carregando, sucesso, semLocalizacao, erro }

class ClimaViewModel extends ChangeNotifier {
  ClimaViewModel(this._repositorio, this._localizacao);

  final ClimaRepository _repositorio;
  final LocalizacaoService _localizacao;
  bool _descartado = false;

  EstadoClima _estado = EstadoClima.inicial;
  ResultadoClima? _resultado;
  String? _mensagem;
  bool _campoCidade = false;

  EstadoClima get estado => _estado;
  ResultadoClima? get resultado => _resultado;
  String? get mensagem => _mensagem;
  bool get carregando => _estado == EstadoClima.carregando;

  /// Caminho alternativo: digitar a cidade em vez de usar a localização.
  bool get campoCidade => _campoCidade;

  void mostrarCampoCidade() {
    _campoCidade = true;
    _avisar();
  }

  Future<void> usarLocalizacao() async {
    _iniciarBusca();
    try {
      final coordenadas = await _localizacao.obter();
      _resultado = await _repositorio.porCoordenadas(coordenadas);
      _estado = EstadoClima.sucesso;
    } on PermissaoNegada {
      _pedirCidade('Sem permissão de localização. Digite a cidade.');
    } on LocalizacaoIndisponivel {
      _pedirCidade('Localização indisponível. Digite a cidade.');
    } on ClimaFalha catch (falha) {
      _estado = EstadoClima.erro;
      _mensagem = falha.mensagem;
    }
    _avisar();
  }

  Future<void> buscarPorCidade(String cidade) async {
    if (cidade.trim().isEmpty) {
      _mensagem = 'Informe a cidade.';
      _avisar();
      return;
    }
    _iniciarBusca();
    try {
      _resultado = await _repositorio.porCidade(cidade);
      _estado = EstadoClima.sucesso;
    } on ClimaFalha catch (falha) {
      _estado = EstadoClima.erro;
      _mensagem = falha.mensagem;
    }
    _avisar();
  }

  void _iniciarBusca() {
    _estado = EstadoClima.carregando;
    _mensagem = null;
    _avisar();
  }

  void _pedirCidade(String mensagem) {
    _estado = EstadoClima.semLocalizacao;
    _mensagem = mensagem;
    _campoCidade = true;
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
