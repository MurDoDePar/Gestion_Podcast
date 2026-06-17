import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  final Connectivity _connectivity = Connectivity();

  NetworkService._internal();

  /// Stream exposant les changements de connexion réseau.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Vérifie l'état actuel de la connexion réseau.
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  /// Raccourci pour savoir si l'appareil dispose d'une connexion réseau.
  Future<bool> isConnected() async {
    final results = await checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Raccourci pour savoir si l'appareil est connecté en Wi-Fi.
  Future<bool> isWifi() async {
    final results = await checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }
}
