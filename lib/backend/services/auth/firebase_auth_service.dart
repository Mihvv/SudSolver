import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            serverClientId:
                '333165744649-h05n9j4tvobt4q434bva1b3ghsl2mpir.apps.googleusercontent.com',
          );

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return _mapUser(result.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Błąd logowania Google');
    } catch (e, stack) {
      throw AuthException('Nieoczekiwany błąd: $e\n$stack');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}
