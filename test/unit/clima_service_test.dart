import 'package:diario_atividades/models/coordenadas.dart';
import 'package:diario_atividades/services/clima_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../fakes.dart';

const _curitiba = Coordenadas(-25.43, -49.27, nome: 'Curitiba');

void main() {
  group('ClimaService', () {
    test('converte a resposta da Open-Meteo em Clima', () async {
      final service = ClimaService(client: clienteClimaOk());

      final clima = await service.buscar(_curitiba);

      expect(clima.temperatura, 24.0);
      expect(clima.codigo, 3);
      expect(clima.descricao, 'nublado');
      expect(clima.local, 'Curitiba');
    });

    test('localiza a cidade digitada', () async {
      final service = ClimaService(client: clienteClimaOk());

      final coordenadas = await service.localizarCidade('curitiba');

      expect(coordenadas.nome, 'Curitiba');
      expect(coordenadas.latitude, -25.43);
    });

    test('status diferente de 200 vira ClimaFalha', () async {
      final service = ClimaService(client: clienteClimaFora());

      expect(service.buscar(_curitiba), throwsA(isA<ClimaFalha>()));
    });

    test('JSON fora do formato esperado vira ClimaFalha', () async {
      final service = ClimaService(
        client: MockClient((_) async => http.Response('{"x": 1}', 200)),
      );

      expect(service.buscar(_curitiba), throwsA(isA<ClimaFalha>()));
    });

    test('corpo que não é JSON vira ClimaFalha', () async {
      final service = ClimaService(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      expect(service.buscar(_curitiba), throwsA(isA<ClimaFalha>()));
    });

    test('demora além do limite vira ClimaFalha', () async {
      final service = ClimaService(
        timeout: const Duration(milliseconds: 20),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      expect(service.buscar(_curitiba), throwsA(isA<ClimaFalha>()));
    });

    test('cidade inexistente não permite usar o cache', () async {
      final service = ClimaService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        service.localizarCidade('xyzxyz'),
        throwsA(
          isA<ClimaFalha>().having(
            (falha) => falha.podeUsarCache,
            'podeUsarCache',
            isFalse,
          ),
        ),
      );
    });
  });
}
