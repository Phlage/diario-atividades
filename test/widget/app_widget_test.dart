import 'package:diario_atividades/app.dart';
import 'package:diario_atividades/repositories/clima_repository.dart';
import 'package:diario_atividades/services/clima_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

Widget _app({
  required FakeAuthService auth,
  FakeAtividadeService? atividades,
}) =>
    DiarioApp(
      auth: auth,
      atividades: atividades ?? FakeAtividadeService(),
      clima: ClimaRepository(
        ClimaService(client: clienteClimaOk()),
        FakeCacheService(),
      ),
      localizacao: FakeLocalizacaoService.negada(),
    );

void main() {
  testWidgets('sem sessão, mostra o login e não a lista', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthService()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botaoEntrar')), findsOneWidget);
    expect(find.text('Minhas atividades'), findsNothing);
  });

  testWidgets('senha errada mostra erro; senha certa abre a lista',
      (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campoEmail')), emailTeste);
    await tester.enterText(find.byKey(const Key('campoSenha')), 'errada123');
    await tester.tap(find.byKey(const Key('botaoEntrar')));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campoSenha')), senhaTeste);
    await tester.tap(find.byKey(const Key('botaoEntrar')));
    await tester.pumpAndSettle();
    expect(find.text('Minhas atividades'), findsOneWidget);
  });

  testWidgets('lista vazia mostra a mensagem de estado vazio', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthService(uidInicial: 'uid-a')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
    expect(find.byKey(const Key('botaoNova')), findsOneWidget);
  });

  testWidgets('erro mostra "Tentar novamente" e a tela se recupera',
      (tester) async {
    final atividades = FakeAtividadeService(falharAoObservar: true);
    await tester.pumpWidget(
      _app(auth: FakeAuthService(uidInicial: 'uid-a'), atividades: atividades),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar suas atividades.'),
      findsOneWidget,
    );

    atividades.falharAoObservar = false;
    await tester.tap(find.byKey(const Key('botaoTentarNovamente')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
  });

  testWidgets('formulário recusa distância inválida', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthService(uidInicial: 'uid-a')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('botaoNova')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campoDistancia')), '0');
    await tester.enterText(find.byKey(const Key('campoDuracao')), '30');
    await tester.ensureVisible(find.byKey(const Key('botaoSalvar')));
    await tester.tap(find.byKey(const Key('botaoSalvar')));
    await tester.pumpAndSettle();

    expect(
      find.text('A distância deve ser maior que 0 e até 500 km.'),
      findsOneWidget,
    );
    expect(find.text('Nova atividade'), findsOneWidget);
  });
}
