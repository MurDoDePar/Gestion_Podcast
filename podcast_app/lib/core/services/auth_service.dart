import '../models/user_profile.dart';

abstract class AuthService {
  Stream<String?> get onAuthStateChanged;
  String? get currentUserId;
  UserProfile? get currentUserProfile;
  Future<String?> signInWithGoogle();
  Future<void> signOut();
}
