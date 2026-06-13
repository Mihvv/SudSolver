import '../../models/app_user.dart';

abstract class IAuthService {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser?> signInWithGoogle();

  Future<void> signOut();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
