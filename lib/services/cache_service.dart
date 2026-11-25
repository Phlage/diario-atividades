import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento local simples de chave e valor.
abstract class CacheService {
  Future<String?> ler(String chave);
  Future<void> salvar(String chave, String valor);
}

class SharedPrefsCacheService implements CacheService {
  @override
  Future<String?> ler(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(chave);
  }

  @override
  Future<void> salvar(String chave, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, valor);
  }
}
