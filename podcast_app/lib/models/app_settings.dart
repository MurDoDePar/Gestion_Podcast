import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_repository.dart';

class AppSettings {
  static const int defaultMaxCacheSize =
      2 * 1024 * 1024 * 1024; // 2 Go par défaut

  /// Lit la taille maximale du cache configurée (en octets) depuis SQLite.
  /// Retourne 2 Go par défaut si aucune valeur n'est configurée.
  static Future<int> getMaxCacheSize() async {
    return DatabaseRepository()
        .getSettingInt('max_cache_size', defaultValue: defaultMaxCacheSize);
  }

  /// Met à jour la taille maximale du cache (en octets) dans SQLite.
  static Future<void> setMaxCacheSize(int maxSizeBytes) async {
    await DatabaseRepository()
        .setSetting('max_cache_size', maxSizeBytes.toString());
  }

  /// Récupère la langue configurée dans l'application (SharedPreferences),
  /// avec 'fr' comme langue par défaut.
  static Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('podstream_lang') ?? 'fr';
    } catch (e) {
      return 'fr';
    }
  }
}
