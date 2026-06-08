import 'dart:async';
import '../../models/app_user.dart';
import 'auth_service.dart';

class MockAuthService implements IAuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  static const _fakeUser = AppUser(
    uid: 'mock-uid-123',
    displayName: 'Test User',
    email: 'test@example.com',
  );

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _current;

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _current = _fakeUser;
    _controller.add(_current);
    return _current;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
