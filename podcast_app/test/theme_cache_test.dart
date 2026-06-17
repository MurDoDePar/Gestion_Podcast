import 'package:flutter_test/flutter_test.dart';
import 'package:podcast_app/models/podcast_model.dart';

// --- Logic representation of getPodcastsByThemeWithCache for testing ---
Future<List<PodcastModel>> simulateGetPodcastsByThemeWithCache({
  required String theme,
  required int? mockCacheTime,
  required List<PodcastModel> mockCacheData,
  required Future<List<PodcastModel>> Function(String) mockFetchApi,
  required Future<void> Function(String, List<PodcastModel>, int) mockSaveCache,
  required int currentTime,
  required bool forceApiError,
  String currentLang = 'en',
  String lastThemeLang = 'en',
  void Function()? mockClearCache,
}) async {
  try {
    const int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

    var cacheTime = mockCacheTime;
    var cacheData = mockCacheData;

    if (currentLang != lastThemeLang) {
      if (mockClearCache != null) {
        mockClearCache();
      }
      cacheTime = null;
      cacheData = [];
    }

    // 1. Vérification : Si le cache existe et est valide (moins de 7 jours)
    if (cacheTime != null && (currentTime - cacheTime) < sevenDaysMs) {
      if (cacheData.isNotEmpty) {
        return cacheData;
      }
    }

    // 2. Rafraîchissement : Cache expiré, absent ou vide, on appelle l'API
    if (forceApiError) {
      throw Exception("Erreur réseau simulée (Offline)");
    }

    final freshPodcasts = await mockFetchApi(theme);

    if (freshPodcasts.isNotEmpty) {
      // Sauvegarde transactionnelle simulée
      await mockSaveCache(theme, freshPodcasts, currentTime);
    }

    return freshPodcasts;
  } catch (e) {
    // 3. Fallback : Si l'API échoue (hors-ligne), on retourne le cache expiré s'il existe
    if (mockCacheData.isNotEmpty && currentLang == lastThemeLang) {
      return mockCacheData;
    }
    return [];
  }
}

void main() {
  group('Themes Cache Offline-First Tests', () {
    const String testTheme = 'Technologie';
    final List<PodcastModel> cachedPodcasts = [
      PodcastModel(
        collectionId: 101,
        collectionName: 'Podcast Tech Cache',
        artistName: 'Artiste Tech Cache',
        artworkUrl: 'https://example.com/cache.jpg',
        feedUrl: 'https://example.com/cache.xml',
      )
    ];
    final List<PodcastModel> freshPodcasts = [
      PodcastModel(
        collectionId: 202,
        collectionName: 'Podcast Tech Fresh',
        artistName: 'Artiste Tech Fresh',
        artworkUrl: 'https://example.com/fresh.jpg',
        feedUrl: 'https://example.com/fresh.xml',
      )
    ];

    test(
        '1. Cache valide (< 7 jours) : Retourne immédiatement le cache sans appeler l\'API',
        () async {
      bool apiCalled = false;
      bool cacheSaved = false;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int cacheTime =
          now - (3 * 24 * 60 * 60 * 1000); // 3 jours d'âge (valide)

      final result = await simulateGetPodcastsByThemeWithCache(
        theme: testTheme,
        mockCacheTime: cacheTime,
        mockCacheData: cachedPodcasts,
        currentTime: now,
        forceApiError: false,
        mockFetchApi: (theme) async {
          apiCalled = true;
          return freshPodcasts;
        },
        mockSaveCache: (theme, list, time) async {
          cacheSaved = true;
        },
      );

      // Le cache est valide, l'API ne doit PAS être appelée
      expect(apiCalled, isFalse);
      expect(cacheSaved, isFalse);
      // Les données retournées proviennent du cache
      expect(result.length, 1);
      expect(result.first.collectionName, 'Podcast Tech Cache');
    });

    test('2. Cache expiré (> 7 jours) : Appelle l\'API et met à jour le cache',
        () async {
      bool apiCalled = false;
      bool cacheSaved = false;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int cacheTime =
          now - (8 * 24 * 60 * 60 * 1000); // 8 jours d'âge (expiré)

      final result = await simulateGetPodcastsByThemeWithCache(
        theme: testTheme,
        mockCacheTime: cacheTime,
        mockCacheData: cachedPodcasts,
        currentTime: now,
        forceApiError: false,
        mockFetchApi: (theme) async {
          apiCalled = true;
          return freshPodcasts;
        },
        mockSaveCache: (theme, list, time) async {
          cacheSaved = true;
          expect(list.first.collectionName, 'Podcast Tech Fresh');
          expect(time, now);
        },
      );

      // Le cache est expiré, l'API doit être appelée et le cache mis à jour
      expect(apiCalled, isTrue);
      expect(cacheSaved, isTrue);
      // Les données retournées sont les nouvelles données
      expect(result.length, 1);
      expect(result.first.collectionName, 'Podcast Tech Fresh');
    });

    test('3. Pas de cache : Appelle l\'API et initialise le cache', () async {
      bool apiCalled = false;
      bool cacheSaved = false;
      final int now = DateTime.now().millisecondsSinceEpoch;

      final result = await simulateGetPodcastsByThemeWithCache(
        theme: testTheme,
        mockCacheTime: null, // Pas d'entrée en cache
        mockCacheData: [],
        currentTime: now,
        forceApiError: false,
        mockFetchApi: (theme) async {
          apiCalled = true;
          return freshPodcasts;
        },
        mockSaveCache: (theme, list, time) async {
          cacheSaved = true;
        },
      );

      expect(apiCalled, isTrue);
      expect(cacheSaved, isTrue);
      expect(result.length, 1);
      expect(result.first.collectionName, 'Podcast Tech Fresh');
    });

    test(
        '4. Cache expiré mais Réseau Offline : Retourne le cache expiré comme Fallback',
        () async {
      bool cacheSaved = false;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int cacheTime =
          now - (10 * 24 * 60 * 60 * 1000); // 10 jours d'âge (expiré)

      final result = await simulateGetPodcastsByThemeWithCache(
        theme: testTheme,
        mockCacheTime: cacheTime,
        mockCacheData: cachedPodcasts,
        currentTime: now,
        forceApiError: true, // Offline !
        mockFetchApi: (theme) async => freshPodcasts,
        mockSaveCache: (theme, list, time) async {
          cacheSaved = true;
        },
      );

      // Tentative d'appel API mais erreur levée, pas de sauvegarde
      expect(cacheSaved, isFalse);
      // Retourne le cache obsolète au lieu de crasher
      expect(result.length, 1);
      expect(result.first.collectionName, 'Podcast Tech Cache');
    });

    test(
        '5. Changement de langue : Invalide le cache même s\'il est récent, appelle l\'API et efface le cache existant',
        () async {
      bool apiCalled = false;
      bool cacheSaved = false;
      bool cacheCleared = false;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int cacheTime =
          now - (2 * 24 * 60 * 60 * 1000); // 2 jours (normalement valide)

      final result = await simulateGetPodcastsByThemeWithCache(
        theme: testTheme,
        mockCacheTime: cacheTime,
        mockCacheData: cachedPodcasts,
        currentTime: now,
        forceApiError: false,
        currentLang: 'fr', // Nouvelle langue
        lastThemeLang: 'en', // Langue du cache
        mockClearCache: () {
          cacheCleared = true;
        },
        mockFetchApi: (theme) async {
          apiCalled = true;
          return freshPodcasts;
        },
        mockSaveCache: (theme, list, time) async {
          cacheSaved = true;
        },
      );

      // La langue ayant changé, le cache récent doit être invalidé
      expect(cacheCleared, isTrue);
      expect(apiCalled, isTrue);
      expect(cacheSaved, isTrue);
      expect(result.length, 1);
      expect(result.first.collectionName, 'Podcast Tech Fresh');
    });
  });
}
