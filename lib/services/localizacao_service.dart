import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/coordenadas.dart';

class PermissaoNegada implements Exception {}

class LocalizacaoIndisponivel implements Exception {}

/// Recurso nativo: localização aproximada do aparelho.
abstract class LocalizacaoService {
  /// Lança [PermissaoNegada] ou [LocalizacaoIndisponivel].
  Future<Coordenadas> obter();
}

class GeolocatorLocalizacaoService implements LocalizacaoService {
  @override
  Future<Coordenadas> obter() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocalizacaoIndisponivel();
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw PermissaoNegada();
    }

    try {
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // Privacidade: duas casas decimais (~1 km) bastam para o clima.
      return Coordenadas(
        _arredondar(posicao.latitude),
        _arredondar(posicao.longitude),
      );
    } on TimeoutException {
      throw LocalizacaoIndisponivel();
    } on LocationServiceDisabledException {
      throw LocalizacaoIndisponivel();
    }
  }

  double _arredondar(double v) => (v * 100).roundToDouble() / 100;
}
