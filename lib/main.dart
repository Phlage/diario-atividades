import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'repositories/clima_repository.dart';
import 'services/atividade_service.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/clima_service.dart';
import 'services/localizacao_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DiarioApp(
      auth: FirebaseAuthService(),
      atividades: FirestoreAtividadeService(),
      clima: ClimaRepository(ClimaService(), SharedPrefsCacheService()),
      localizacao: GeolocatorLocalizacaoService(),
    ),
  );
}
