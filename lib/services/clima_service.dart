import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clima.dart';
import '../models/coordenadas.dart';

/// Falha do serviço de clima já traduzida para uma mensagem segura.
class ClimaFalha implements Exception {
  const ClimaFalha(this.mensagem, {this.podeUsarCache = true});

  final String mensagem;

  /// Falso quando o cache não ajudaria (ex.: cidade não encontrada).
  final bool podeUsarCache;

  @override
  String toString() => 'ClimaFalha: $mensagem';
}

/// Acesso HTTP à API pública Open-Meteo (não exige chave).
class ClimaService {
  ClimaService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<Clima> buscar(Coordenadas c) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${c.latitude}',
      'longitude': '${c.longitude}',
      'current': 'temperature_2m,weather_code',
    });
    final json = await _getJson(uri);
    try {
      return Clima.fromOpenMeteo(json, local: c.nome ?? 'Local atual');
    } on FormatException {
      throw const ClimaFalha('Resposta inválida do serviço de clima.');
    }
  }

  Future<Coordenadas> localizarCidade(String cidade) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': cidade.trim(),
      'count': '1',
      'language': 'pt',
    });
    final json = await _getJson(uri);
    final resultados = json['results'];
    if (resultados is! List || resultados.isEmpty) {
      throw const ClimaFalha('Cidade não encontrada.', podeUsarCache: false);
    }
    final primeiro = resultados.first;
    if (primeiro is! Map ||
        primeiro['latitude'] is! num ||
        primeiro['longitude'] is! num) {
      throw const ClimaFalha('Resposta inválida do serviço de clima.');
    }
    return Coordenadas(
      (primeiro['latitude'] as num).toDouble(),
      (primeiro['longitude'] as num).toDouble(),
      nome: primeiro['name'] as String? ?? cidade.trim(),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final resposta = await _client.get(uri).timeout(timeout);
      if (resposta.statusCode != 200) {
        throw ClimaFalha(
          'Serviço de clima indisponível (${resposta.statusCode}).',
        );
      }
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is! Map<String, dynamic>) {
        throw const ClimaFalha('Resposta inválida do serviço de clima.');
      }
      return corpo;
    } on TimeoutException {
      throw const ClimaFalha('O serviço de clima demorou para responder.');
    } on http.ClientException {
      throw const ClimaFalha('Sem conexão com o serviço de clima.');
    } on FormatException {
      throw const ClimaFalha('Resposta inválida do serviço de clima.');
    }
  }
}
