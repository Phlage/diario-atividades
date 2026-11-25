import 'package:diario_atividades/repositories/clima_repository.dart';
import 'package:diario_atividades/services/clima_service.dart';
import 'package:diario_atividades/viewmodels/clima_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

ClimaRepository _repoOk() =>
    ClimaRepository(ClimaService(client: clienteClimaOk()), FakeCacheService());

void main() {
  group('ClimaViewModel', () {
    test('localização autorizada leva a sucesso com dado da rede', () async {
      final vm = ClimaViewModel(_repoOk(), FakeLocalizacaoService.autorizada());

      await vm.usarLocalizacao();

      expect(vm.estado, EstadoClima.sucesso);
      expect(vm.resultado!.origem, OrigemClima.rede);
      expect(vm.campoCidade, isFalse);
    });

    test('permissão negada abre a alternativa de digitar a cidade', () async {
      final vm = ClimaViewModel(_repoOk(), FakeLocalizacaoService.negada());

      await vm.usarLocalizacao();
      expect(vm.estado, EstadoClima.semLocalizacao);
      expect(vm.campoCidade, isTrue);
      expect(vm.mensagem, contains('Digite a cidade'));

      await vm.buscarPorCidade('Curitiba');
      expect(vm.estado, EstadoClima.sucesso);
      expect(vm.resultado!.clima.local, 'Curitiba');
    });

    test('cidade em branco não dispara busca', () async {
      final vm = ClimaViewModel(_repoOk(), FakeLocalizacaoService.negada());

      await vm.buscarPorCidade('   ');

      expect(vm.estado, EstadoClima.inicial);
      expect(vm.mensagem, 'Informe a cidade.');
    });

    test('serviço fora do ar e sem cache leva a erro com mensagem', () async {
      final vm = ClimaViewModel(
        ClimaRepository(
          ClimaService(client: clienteClimaFora()),
          FakeCacheService(),
        ),
        FakeLocalizacaoService.autorizada(),
      );

      await vm.usarLocalizacao();

      expect(vm.estado, EstadoClima.erro);
      expect(vm.mensagem, isNotNull);
      expect(vm.resultado, isNull);
    });
  });
}
