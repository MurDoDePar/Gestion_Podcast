import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test basique (pour éviter les erreurs s\'il n\'y a pas de tests)', () {
    // Ce test passe toujours. Il sert juste à éviter que 'flutter test'
    // ne retourne une erreur quand le dossier 'test' est vide.
    expect(true, isTrue);
  });
}
