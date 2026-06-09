import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class AppSettings {
  static const int defaultMaxCacheSize =
      2 * 1024 * 1024 * 1024; // 2 Go par défaut

  /// Lit la taille maximale du cache configurée (en octets) depuis SQLite.
  /// Retourne 2 Go par défaut si aucune valeur n'est configurée.
  static Future<int> getMaxCacheSize() async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['max_cache_size'],
      );
      if (maps.isEmpty || maps.first['value'] == null) {
        return defaultMaxCacheSize;
      }
      return int.tryParse(maps.first['value'] as String) ?? defaultMaxCacheSize;
    } catch (e) {
      return defaultMaxCacheSize;
    }
  }

  /// Met à jour la taille maximale du cache (en octets) dans SQLite.
  static Future<void> setMaxCacheSize(int maxSizeBytes) async {
    try {
      final helper = DatabaseHelper();
      final db = await helper.database;
      await db.insert(
        'settings',
        {
          'key': 'max_cache_size',
          'value': maxSizeBytes.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Échec silencieux
    }
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
