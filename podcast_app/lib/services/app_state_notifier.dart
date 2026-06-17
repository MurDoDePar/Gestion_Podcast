import 'package:flutter/foundation.dart';

class AppStateNotifier extends ChangeNotifier {
  static final AppStateNotifier _instance = AppStateNotifier._internal();

  factory AppStateNotifier() {
    return _instance;
  }

  AppStateNotifier._internal() {
//     print('DEBUG: AppStateNotifier instance créée. HashCode: $hashCode');
  }

  void notifyCacheUpdate() {
//     print('DEBUG: Signal de mise à jour émis par AppStateNotifier');
//     print('DEBUG: Instance AppStateNotifier HashCode: $hashCode');
//     print('DEBUG [Bus]: Signal de mise à jour reçu par l\'UI via le Bus.');
    notifyListeners();
  }
}
