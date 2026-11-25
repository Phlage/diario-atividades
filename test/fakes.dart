// Dublês em memória usados pelos testes de unidade, widget e integração.
import 'dart:async';
import 'dart:convert';

import 'package:diario_atividades/models/atividade.dart';
import 'package:diario_atividades/models/coordenadas.dart';
import 'package:diario_atividades/services/atividade_service.dart';
import 'package:diario_atividades/services/auth_service.dart';
import 'package:diario_atividades/services/cache_service.dart';
import 'package:diario_atividades/services/localizacao_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const emailTeste = 'ana@teste.dev';
const senhaTeste = 'senha123';

class FakeAuthService implements AuthService {
  FakeAuthService({String? uidInicial}) : _uid = uidInicial;

  final _mudancas = StreamController<String?>.broadcast();
  final Map<String, String> _contas = {emailTeste: senhaTeste};
  String? _uid;

  @override
  Stream<String?> get uidStream async* {
    yield _uid;
    yield* _mudancas.stream;
  }

  @override
  String? get uidAtual => _uid;

  @override
  Future<void> entrar(String email, String senha) async {
    if (_contas[email] != senha) {
      throw const AuthFalha('E-mail ou senha incorretos.');
    }
    _definir('uid-$email');
  }

  @override
  Future<void> cadastrar(String email, String senha) async {
    if (_contas.containsKey(email)) {
      throw const AuthFalha('Este e-mail já está cadastrado.');
    }
    _contas[email] = senha;
    _definir('uid-$email');
  }

  @override
  Future<void> sair() async => _definir(null);

  void _definir(String? uid) {
    _uid = uid;
    _mudancas.add(uid);
  }
}

class FakeAtividadeService implements AtividadeService {
  FakeAtividadeService({this.falharAoObservar = false});

  /// Simula indisponibilidade do backend na leitura.
  bool falharAoObservar;

  final _mudancas = StreamController<void>.broadcast();
  final Map<String, List<Atividade>> _porUsuario = {};
  int _proximoId = 1;

  List<Atividade> _lista(String uid) {
    final lista = [...?_porUsuario[uid]];
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  @override
  Stream<List<Atividade>> observar(String uid) async* {
    if (falharAoObservar) throw Exception('falha simulada');
    yield _lista(uid);
    yield* _mudancas.stream.map((_) => _lista(uid));
  }

  @override
  Future<void> criar(String uid, Atividade atividade) async {
    final criada = Atividade.fromMap('id-${_proximoId++}', atividade.toMap());
    _porUsuario.putIfAbsent(uid, () => []).add(criada);
    _mudancas.add(null);
  }

  @override
  Future<void> atualizar(String uid, Atividade atividade) async {
    final lista = _porUsuario[uid] ?? [];
    final indice = lista.indexWhere((a) => a.id == atividade.id);
    if (indice < 0) throw Exception('documento inexistente');
    lista[indice] = atividade;
    _mudancas.add(null);
  }

  @override
  Future<void> remover(String uid, String id) async {
    _porUsuario[uid]?.removeWhere((a) => a.id == id);
    _mudancas.add(null);
  }
}

class FakeCacheService implements CacheService {
  final Map<String, String> dados = {};

  @override
  Future<String?> ler(String chave) async => dados[chave];

  @override
  Future<void> salvar(String chave, String valor) async {
    dados[chave] = valor;
  }
}

class FakeLocalizacaoService implements LocalizacaoService {
  FakeLocalizacaoService.autorizada([
    this.coordenadas = const Coordenadas(-25.43, -49.27),
  ]) : erro = null;

  FakeLocalizacaoService.negada()
      : coordenadas = null,
        erro = PermissaoNegada();

  final Coordenadas? coordenadas;
  final Exception? erro;

  @override
  Future<Coordenadas> obter() async {
    if (erro != null) throw erro!;
    return coordenadas!;
  }
}

/// Cliente HTTP que responde como a Open-Meteo: 24 °C, nublado, Curitiba.
http.Client clienteClimaOk() => MockClient((requisicao) async {
      if (requisicao.url.host.startsWith('geocoding')) {
        return http.Response(
          jsonEncode({
            'results': [
              {'name': 'Curitiba', 'latitude': -25.43, 'longitude': -49.27},
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'current': {'temperature_2m': 24.0, 'weather_code': 3},
        }),
        200,
      );
    });

/// Cliente HTTP que simula o serviço fora do ar.
http.Client clienteClimaFora() =>
    MockClient((_) async => http.Response('erro', 503));
