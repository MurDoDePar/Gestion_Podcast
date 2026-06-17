import 'package:get_it/get_it.dart';
import 'auth_service.dart';
import 'podcast_sync_service.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/services/firebase_podcast_sync_service.dart';
import '../../services/sqlite_podcast_repository.dart';
import '../../services/sql_connect_repository.dart';
import '../../services/itunes_search_gateway.dart';
import '../../services/podcast_cache_manager.dart';
import '../../services/history_tab_service.dart';
import '../../services/search_page_service.dart';
import '../../services/theme_tab_service.dart';
import '../../services/affinity_tab_service.dart';
import '../../services/settings_page_service.dart';
import '../../services/podcasts_tab_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Core Services
  locator.registerLazySingleton<AuthService>(() => FirebaseAuthService());
  locator.registerLazySingleton<PodcastSyncService>(
      () => FirebasePodcastSyncService());

  // Data Repositories (Singletons)
  locator.registerLazySingleton<SqlitePodcastRepository>(
      () => SqlitePodcastRepository());
  locator.registerLazySingleton<SqlConnectRepository>(
      () => SqlConnectRepository());
  locator
      .registerLazySingleton<ITunesSearchGateway>(() => ITunesSearchGateway());
  locator.registerLazySingleton<PodcastCacheManager>(() => PodcastCacheManager(
        sqliteRepository: locator<SqlitePodcastRepository>(),
      ));

  // UI Services (Factories)
  locator.registerFactory<HistoryTabService>(() => HistoryTabService(
        sqliteRepository: locator<SqlitePodcastRepository>(),
      ));
  locator.registerFactory<SearchPageService>(() => SearchPageService(
        itunesGateway: locator<ITunesSearchGateway>(),
      ));
  locator.registerFactory<ThemeTabService>(() => ThemeTabService(
        sqliteRepository: locator<SqlitePodcastRepository>(),
        itunesGateway: locator<ITunesSearchGateway>(),
      ));
  locator.registerFactory<AffinityTabService>(() => AffinityTabService(
        sqliteRepository: locator<SqlitePodcastRepository>(),
        sqlConnectRepository: locator<SqlConnectRepository>(),
        authService: locator<AuthService>(),
      ));
  locator.registerFactory<SettingsPageService>(() => SettingsPageService(
        sqliteRepository: locator<SqlitePodcastRepository>(),
        cacheManager: locator<PodcastCacheManager>(),
      ));
  locator.registerFactory<PodcastsTabService>(() => PodcastsTabService(
        sqliteRepository: locator<SqlitePodcastRepository>(),
        sqlConnectRepository: locator<SqlConnectRepository>(),
        cacheManager: locator<PodcastCacheManager>(),
        authService: locator<AuthService>(),
      ));
}
