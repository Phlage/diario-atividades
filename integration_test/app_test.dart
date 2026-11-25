// Fluxo de integração: roda o app inteiro em um aparelho ou emulador.
//
// Ambiente: Firebase, rede e GPS são trocados por dublês em memória
// (test/fakes.dart), então o teste não depende de internet nem deixa
// dados para limpar. Conta de teste: ana@teste.dev (fictícia).
//
// Executar: flutter test integration_test/app_test.dart -d <id-do-aparelho>
import 'package:diario_atividades/app.dart';
import 'package:diario_atividades/repositories/clima_repository.dart';
import 'package:diario_atividades/services/clima_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login -> permissão negada -> cidade -> salvar -> lista -> logout',
    (tester) async {
      await tester.pumpWidget(
        DiarioApp(
          auth: FakeAuthService(),
          atividades: FakeAtividadeService(),
          clima: ClimaRepository(
            ClimaService(client: clienteClimaOk()),
            FakeCacheService(),
          ),
          localizacao: FakeLocalizacaoService.negada(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Login
      await tester.enterText(find.byKey(const Key('campoEmail')), emailTeste);
      await tester.enterText(find.byKey(const Key('campoSenha')), senhaTeste);
      await tester.tap(find.byKey(const Key('botaoEntrar')));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);

      // 2. Nova atividade
      await tester.tap(find.byKey(const Key('botaoNova')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campoDistancia')), '5,2');
      await tester.enterText(find.byKey(const Key('campoDuracao')), '30');

      // 3. Permissão de localização negada -> alternativa por cidade
      await tester.ensureVisible(find.byKey(const Key('botaoLocalizacao')));
      await tester.tap(find.byKey(const Key('botaoLocalizacao')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campoCidade')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('campoCidade')), 'Curitiba');
      await tester.ensureVisible(find.byKey(const Key('botaoBuscarClima')));
      await tester.tap(find.byKey(const Key('botaoBuscarClima')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cartaoClima')), findsOneWidget);
      expect(find.textContaining('24 °C'), findsOneWidget);

      // 4. Salvar e conferir na lista
      await tester.ensureVisible(find.byKey(const Key('botaoSalvar')));
      await tester.tap(find.byKey(const Key('botaoSalvar')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('Caminhada · 5,2 km · 30 min'), findsOneWidget);
      expect(find.textContaining('Curitiba: 24 °C, nublado'), findsOneWidget);

      // 5. Logout devolve à tela de login
      await tester.tap(find.byKey(const Key('botaoSair')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('botaoEntrar')), findsOneWidget);
      expect(find.text('Minhas atividades'), findsNothing);
    },
  );
}
