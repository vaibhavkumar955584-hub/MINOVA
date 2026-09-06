import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

/// Wraps FirebaseAuth operations.
/// Never stores passwords. Never sends MPIN to Firebase.
/// Translates Firebase exceptions into human-readable strings.
class FirebaseAuthService {
  final fb.FirebaseAuth? _auth;

  FirebaseAuthService({fb.FirebaseAuth? auth}) : _auth = auth;

  bool get isAvailable => _initializedAuth != null;

  fb.FirebaseAuth? get _initializedAuth {
    if (_auth != null) return _auth;
    return Firebase.apps.isEmpty ? null : fb.FirebaseAuth.instance;
  }

  fb.FirebaseAuth get _requiredAuth =>
      _initializedAuth ??
      (throw const AuthException('Firebase is unavailable.'));

  fb.User? get currentUser => _initializedAuth?.currentUser;

  Stream<fb.User?> get authStateChanges =>
      _initializedAuth?.authStateChanges() ?? const Stream.empty();

  /// Create an email/password account in the configured Firebase project.
  /// Sign in with email + password.
  /// Throws [AuthException] with user-friendly message on failure.
  Future<fb.User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _requiredAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (_) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  /// Send a Firebase password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _requiredAuth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Start phone authentication. Complete it with [signInWithPhoneCode].
  /// Re-authenticate the current user (required before MPIN reset).
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _requiredAuth.currentUser?.reauthenticateWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Sign out from Firebase.
  Future<void> signOut() async {
    await _requiredAuth.signOut();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'Your account has been disabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Thrown by [FirebaseAuthService] with a human-readable message.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
