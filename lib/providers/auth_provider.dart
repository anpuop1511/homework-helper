import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

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
  String? _username;
  bool _usernameLoaded = false;

  User? get currentUser => _user;
  bool get isSignedIn => _user != null;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get currentUserEmail => _user?.email;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  /// The user's @handle, or null if not yet chosen.
  String? get username => _username;

  /// True once the username lookup from Firestore has completed (or failed).
  /// Use this to distinguish "still loading" from "user has no handle yet".
  bool get usernameLoaded => _usernameLoaded;

  AuthProvider({bool firebaseReady = true}) : _firebaseReady = firebaseReady {
    if (_firebaseReady) {
      // Keep _user in sync with Firebase's auth state stream.
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _user = user;
        if (user != null) {
          _usernameLoaded = false;
          _loadUsername(user.uid);
        } else {
          _username = null;
          _usernameLoaded = false;
        }
        notifyListeners();
      });
      // Initialise synchronously so the first build has the correct value.
      _user = FirebaseAuth.instance.currentUser;
      if (_user != null) {
        _loadUsername(_user!.uid);
      } else {
        _usernameLoaded = true;
      }
    } else {
      _usernameLoaded = true;
    }
  }

  /// Loads the @handle from Firestore (non-blocking; notifies when done).
  void _loadUsername(String uid) {
    DatabaseService.instance.getUsernameForUid(uid).then((handle) {
      _username = handle;
      _usernameLoaded = true;
      notifyListeners();
    }).catchError((_) {
      _usernameLoaded = true;
      notifyListeners();
    });
  }

  /// Sets the username directly in memory without a Firestore round-trip.
  /// Use this immediately after a successful [claimUsername] call so the
  /// router navigates away from the handle screen without waiting for
  /// Firestore to propagate the write.
  void setUsernameDirectly(String handle) {
    _username = handle.toLowerCase().trim();
    _usernameLoaded = true;
    notifyListeners();
  }

  /// Refreshes the in-memory username from Firestore.  Call after the user
  /// successfully claims a new handle.
  Future<void> refreshUsername() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      _username = await DatabaseService.instance.getUsernameForUid(uid);
      _usernameLoaded = true;
      notifyListeners();
    } catch (_) {
      _usernameLoaded = true;
      notifyListeners();
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws a user-friendly [String] message on error so callers can show it
  /// directly in a [SnackBar] without parsing [FirebaseAuthException] codes.
  Future<void> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Firebase auth is not available.');
    }
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] signIn failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Creates a new account with [email] and [password], then updates the
  /// display name to [displayName] if provided.
  Future<void> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Firebase auth is not available.');
    }
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential?.user?.updateDisplayName(displayName);
        // Reload so currentUser.displayName is up-to-date immediately.
        await auth.currentUser?.reload();
        _user = auth.currentUser;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] signUp failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Firebase auth is not available.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] password reset failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    await _auth?.currentUser?.sendEmailVerification();
  }

  /// Re-authenticates the current user with their password to verify it.
  ///
  /// Throws a [FirebaseAuthException] if the password is wrong.
  Future<void> verifyCurrentPassword(String password) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      throw StateError('No signed-in user.');
    }
    final email = user.email;
    if (email == null) {
      throw StateError('Current user has no email.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Converts a [FirebaseAuthException] code into a human-readable message.
  static String friendlyError(FirebaseAuthException e) {
    final message = e.message?.toLowerCase() ?? '';
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
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this Firebase project.';
      case 'internal-error':
        if (message.contains('identitytoolkit') || message.contains('blocked')) {
          return 'Firebase is blocking password sign-in requests. Enable Email/Password sign-in and check your Google Cloud API key restrictions.';
        }
        return e.message ?? 'An unexpected error occurred.';
      default:
        if (message.contains('identitytoolkit') || message.contains('blocked')) {
          return 'Firebase is blocking password sign-in requests. Enable Email/Password sign-in and check your Google Cloud API key restrictions.';
        }
        return e.message ?? 'An unexpected error occurred.';
    }
  }

  static String friendlyErrorFromObject(Object error) {
    if (error is FirebaseAuthException) {
      return friendlyError(error);
    }
    if (error is StateError && error.message.contains('Firebase auth is not available')) {
      return 'Firebase is not ready on this device. Check Firebase initialization and your Firebase config files.';
    }
    return 'Something went wrong. Please try again.';
  }
}
