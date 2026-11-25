# Diário de Atividades

Aplicativo Flutter para registrar caminhadas, corridas e pedaladas junto com o
clima do local. Trabalho final de Desenvolvimento Mobile II.

- **Autenticação:** Firebase Auth (e-mail e senha), sessão persistida e logout.
- **Dados:** Firestore em `users/{uid}/atividades`, isolados por usuário em
  `firestore.rules`.
- **Serviço Web:** Open-Meteo (clima e busca de cidade), sem chave de API.
- **Offline:** último clima salvo no aparelho, exibido com aviso de origem;
  a lista usa o cache local do Firestore.
- **Recurso nativo:** localização aproximada; se negada, o usuário digita a
  cidade. As coordenadas não são salvas.

## Arquitetura (MVVM)

```
View  ->  ViewModel  ->  Repository  ->  Service
lib/views/atividades_view.dart
          lib/viewmodels/atividades_viewmodel.dart
                         lib/repositories/atividade_repository.dart
                                         lib/services/atividade_service.dart (Firestore)
                                         lib/services/auth_service.dart      (Firebase Auth)
lib/views/atividade_form_view.dart
          lib/viewmodels/clima_viewmodel.dart
                         lib/repositories/clima_repository.dart
                                         lib/services/clima_service.dart       (HTTP)
                                         lib/services/cache_service.dart       (shared_preferences)
                         lib/services/localizacao_service.dart                 (geolocator)
lib/views/login_view.dart, lib/views/auth_gate.dart
          lib/viewmodels/auth_viewmodel.dart  ->  lib/services/auth_service.dart
```

As dependências apontam sempre para a direita. As Views não conhecem Firebase,
HTTP nem GPS; os Services são injetados em `lib/main.dart`, o que permite
trocá-los por dublês nos testes (`test/fakes.dart`).

## Como reproduzir a partir de um clone limpo

Pré-requisitos: Flutter estável (Dart 3.5 ou superior), Android SDK, uma conta
Firebase e as ferramentas `firebase-tools` e `flutterfire_cli`.

```bash
git clone https://github.com/Phlage/diario-atividades.git
cd diario-atividades

# 1. Gera a pasta android/ (não sobrescreve os arquivos existentes)
flutter create --project-name diario_atividades --org dev.phlage --platforms android .

# 2. Dependências
flutter pub get
```

3. As permissões `INTERNET` e `ACCESS_COARSE_LOCATION` já estão em
   `android/app/src/main/AndroidManifest.xml`.

4. Firebase (configuração local, não versionada):
   - crie um projeto no console do Firebase;
   - ative **Authentication > E-mail/senha** e crie o **Firestore**;
   - rode `flutterfire configure --platforms=android`, que gera
     `lib/firebase_options.dart`;
   - publique as regras: `firebase deploy --only firestore:rules`
     (ou cole o conteúdo de `firestore.rules` no console).

5. Verificação e execução:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <id-do-aparelho>
flutter run
```

6. Release. A assinatura lê `android/key.properties` (fora do Git), no formato:

```properties
storePassword=<senha>
keyPassword=<senha>
keyAlias=diario
storeFile=/caminho/absoluto/diario-release.jks
```

Sem esse arquivo, o build de release usa a chave de debug.

```bash
flutter build apk --release
flutter build appbundle --release
```

## Testes

| Tipo | Arquivo | O que protege |
|---|---|---|
| Unidade | `test/unit/atividade_test.dart` | validação de distância e duração; conversão do modelo |
| Unidade | `test/unit/clima_service_test.dart` | conversão do JSON; status, formato inválido e timeout viram `ClimaFalha` |
| Unidade | `test/unit/clima_repository_test.dart` | rede primeiro, cache como reserva, origem sinalizada |
| Unidade | `test/unit/atividades_viewmodel_test.dart` | transições carregando, vazio, sucesso, erro e recuperação |
| Unidade | `test/unit/clima_viewmodel_test.dart` | permissão negada abre a alternativa por cidade |
| Widget | `test/widget/app_widget_test.dart` | login, estado vazio, erro com "Tentar novamente", validação do formulário |
| Integração | `integration_test/app_test.dart` | login, permissão negada, cidade, salvar, lista e logout no aparelho |

Os testes automatizados usam dublês em memória. As regras de segurança são
verificadas no backend real (Simulador de regras do console do Firebase).

## Privacidade

- A localização é pedida só quando o usuário toca em "Usar minha localização".
- Usa-se precisão aproximada, arredondada a duas casas decimais (cerca de 1 km).
- As coordenadas servem apenas para a consulta à Open-Meteo e não são gravadas
  no Firestore, no cache nem em logs. Fica salvo só o nome do lugar e o clima.
- Nenhum segredo é versionado: keystore, `key.properties` e a configuração do
  Firebase estão no `.gitignore`.

## Recursos externos

Flutter, Firebase (Auth e Firestore), Open-Meteo, pacotes `provider`, `http`,
`shared_preferences` e `geolocator`. O código foi desenvolvido com apoio de
assistente de IA (Claude, da Anthropic).
