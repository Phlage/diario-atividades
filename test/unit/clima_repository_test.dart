import 'package:diario_atividades/models/coordenadas.dart';
import 'package:diario_atividades/repositories/clima_repository.dart';
import 'package:diario_atividades/services/clima_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

const _curitiba = Coordenadas(-25.43, -49.27, nome: 'Curitiba');

void main() {
  group('ClimaRepository (estratégia offline)', () {
    test('com rede: devolve origem rede e grava o cache', () async {
      final cache = FakeCacheService();
      final repo =
          ClimaRepository(ClimaService(client: clienteClimaOk()), cache);

      final resultado = await repo.porCoordenadas(_curitiba);

      expect(resultado.origem, OrigemClima.rede);
      expect(resultado.clima.temperatura, 24.0);
      expect(cache.dados[ClimaRepository.chaveCache], isNotNull);
    });

    test('sem rede e com cache: devolve o dado salvo com origem cache',
        () async {
      final cache = FakeCacheService();
      await ClimaRepository(ClimaService(client: clienteClimaOk()), cache)
          .porCoordenadas(_curitiba);

      final offline =
          ClimaRepository(ClimaService(client: clienteClimaFora()), cache);
      final resultado = await offline.porCoordenadas(_curitiba);

      expect(resultado.origem, OrigemClima.cache);
      expect(resultado.clima.local, 'Curitiba');
      expect(resultado.clima.temperatura, 24.0);
    });

    test('sem rede e sem cache: propaga ClimaFalha', () async {
      final repo = ClimaRepository(
        ClimaService(client: clienteClimaFora()),
        FakeCacheService(),
      );

      expect(repo.porCoordenadas(_curitiba), throwsA(isA<ClimaFalha>()));
    });

    test('cache corrompido é tratado como ausente', () async {
      final cache = FakeCacheService()
        ..dados[ClimaRepository.chaveCache] = 'não é json';
      final repo =
          ClimaRepository(ClimaService(client: clienteClimaFora()), cache);

      expect(repo.porCoordenadas(_curitiba), throwsA(isA<ClimaFalha>()));
    });
  });
}
