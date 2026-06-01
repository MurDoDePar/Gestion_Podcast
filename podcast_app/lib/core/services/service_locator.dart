import 'package:get_it/get_it.dart';
import 'auth_service.dart';
import 'podcast_sync_service.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/services/firebase_podcast_sync_service.dart';

final locator = GetIt.instance;
void setupLocator() {
  locator.registerLazySingleton<AuthService>(() => FirebaseAuthService());
  locator.registerLazySingleton<PodcastSyncService>(
      () => FirebasePodcastSyncService());
}
