import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase Email/Password authentication state.
///
/// Listens to [FirebaseAuth.instance.authStateChanges()] so the rest of the
/// app can react to sign-in / sign-out events without polling.
///
/// When [firebaseReady] is false (i.e. Firebase was not initialised because
/// the placeholder `firebase_options.dart` has not been replaced), all auth
/// operations are no-ops and the user is treated as a guest.
class AuthProvider extends ChangeNotifier {
  final bool _firebaseReady;
  FirebaseAuth? get _auth =>
      _firebaseReady ? FirebaseAuth.instance : null;

  User? _user;

  User? get currentUser => _user;
  bool get isSignedIn => _user != null;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider({bool firebaseReady = true}) : _firebaseReady = firebaseReady {
    if (_firebaseReady) {
      // Keep _user in sync with Firebase's auth state stream.
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
      // Initialise synchronously so the first build has the correct value.
      _user = FirebaseAuth.instance.currentUser;
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws a user-friendly [String] message on error so callers can show it
  /// directly in a [SnackBar] without parsing [FirebaseAuthException] codes.
  Future<void> signIn(String email, String password) async {
    await _auth?.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates a new account with [email] and [password], then updates the
  /// display name to [displayName] if provided.
  Future<void> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth?.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential?.user?.updateDisplayName(displayName);
      // Reload so currentUser.displayName is up-to-date immediately.
      await _auth?.currentUser?.reload();
      _user = _auth?.currentUser;
      notifyListeners();
    }
  }

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth?.sendPasswordResetEmail(email: email.trim());
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    await _auth?.currentUser?.sendEmailVerification();
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Converts a [FirebaseAuthException] code into a human-readable message.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
