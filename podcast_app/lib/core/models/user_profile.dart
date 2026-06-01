class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}
