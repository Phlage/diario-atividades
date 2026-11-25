import 'package:diario_atividades/models/atividade.dart';
import 'package:diario_atividades/repositories/atividade_repository.dart';
import 'package:diario_atividades/viewmodels/atividades_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

Atividade _corrida({double km = 5}) => Atividade(
      tipo: 'Corrida',
      distanciaKm: km,
      duracaoMin: 30,
      data: DateTime(2026, 11, 15),
    );

void main() {
  group('AtividadesViewModel', () {
    test('carregando -> vazio quando o usuário não tem atividades', () async {
      final vm = AtividadesViewModel(
        AtividadeRepository(
          FakeAuthService(uidInicial: 'uid-a'),
          FakeAtividadeService(),
        ),
      );

      vm.iniciar();
      expect(vm.estado, EstadoLista.carregando);

      await pumpEventQueue();
      expect(vm.estado, EstadoLista.vazio);
    });

    test('vazio -> sucesso ao salvar, e volta a vazio ao remover', () async {
      final vm = AtividadesViewModel(
        AtividadeRepository(
          FakeAuthService(uidInicial: 'uid-a'),
          FakeAtividadeService(),
        ),
      )..iniciar();
      await pumpEventQueue();

      expect(await vm.salvar(_corrida(km: 5.2)), isTrue);
      await pumpEventQueue();
      expect(vm.estado, EstadoLista.sucesso);
      expect(vm.atividades, hasLength(1));
      expect(vm.totalKm, 5.2);

      expect(await vm.remover(vm.atividades.single.id!), isTrue);
      await pumpEventQueue();
      expect(vm.estado, EstadoLista.vazio);
    });

    test('erro -> tentarNovamente recupera quando o backend volta', () async {
      final service = FakeAtividadeService(falharAoObservar: true);
      final vm = AtividadesViewModel(
        AtividadeRepository(FakeAuthService(uidInicial: 'uid-a'), service),
      )..iniciar();
      await pumpEventQueue();
      expect(vm.estado, EstadoLista.erro);
      expect(vm.mensagemErro, isNotNull);

      service.falharAoObservar = false;
      vm.tentarNovamente();
      expect(vm.estado, EstadoLista.carregando);
      await pumpEventQueue();
      expect(vm.estado, EstadoLista.vazio);
    });

    test('sem sessão, a lista entra em erro em vez de quebrar', () async {
      final vm = AtividadesViewModel(
        AtividadeRepository(FakeAuthService(), FakeAtividadeService()),
      )..iniciar();
      await pumpEventQueue();

      expect(vm.estado, EstadoLista.erro);
    });

    test('cada usuário enxerga apenas as próprias atividades', () async {
      final service = FakeAtividadeService();
      final vmA = AtividadesViewModel(
        AtividadeRepository(FakeAuthService(uidInicial: 'uid-a'), service),
      )..iniciar();
      final vmB = AtividadesViewModel(
        AtividadeRepository(FakeAuthService(uidInicial: 'uid-b'), service),
      )..iniciar();
      await pumpEventQueue();

      await vmA.salvar(_corrida());
      await pumpEventQueue();

      expect(vmA.atividades, hasLength(1));
      expect(vmB.atividades, isEmpty);
    });
  });
}
