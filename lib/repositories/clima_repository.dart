import 'dart:convert';

import '../models/clima.dart';
import '../models/coordenadas.dart';
import '../services/cache_service.dart';
import '../services/clima_service.dart';

enum OrigemClima { rede, cache }

class ResultadoClima {
  const ResultadoClima(this.clima, this.origem);
  final Clima clima;
  final OrigemClima origem;
}

/// Estratégia offline: rede primeiro; se falhar, último clima salvo,
/// sempre informando a origem do dado.
class ClimaRepository {
  ClimaRepository(this._service, this._cache);

  static const chaveCache = 'ultimo_clima';

  final ClimaService _service;
  final CacheService _cache;

  Future<ResultadoClima> porCoordenadas(Coordenadas coordenadas) =>
      _comCache(() => _service.buscar(coordenadas));

  Future<ResultadoClima> porCidade(String cidade) => _comCache(
        () async => _service.buscar(await _service.localizarCidade(cidade)),
      );

  Future<ResultadoClima> _comCache(Future<Clima> Function() buscar) async {
    try {
      final clima = await buscar();
      await _cache.salvar(chaveCache, jsonEncode(clima.toJson()));
      return ResultadoClima(clima, OrigemClima.rede);
    } on ClimaFalha catch (falha) {
      if (!falha.podeUsarCache) rethrow;
      final salvo = await _lerCache();
      if (salvo == null) rethrow;
      return ResultadoClima(salvo, OrigemClima.cache);
    }
  }

  Future<Clima?> _lerCache() async {
    final texto = await _cache.ler(chaveCache);
    if (texto == null) return null;
    try {
      return Clima.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      return null; // cache corrompido é tratado como ausente
    }
  }
}
