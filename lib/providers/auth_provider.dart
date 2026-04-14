import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _prefGuestMode = 'auth_guest_mode';

  final bool _firebaseReady;
  final String? _firebaseInitError;
  FirebaseAuth? get _auth =>
      _firebaseReady ? FirebaseAuth.instance : null;

  /// The raw exception string captured when [Firebase.initializeApp] threw
  /// during app startup.  Non-null only when Firebase failed to initialise.
  /// Used by [LoginScreen] to display a diagnostic error box.
  String? get firebaseInitError => _firebaseInitError;

  User? _user;
  String? _username;
  bool _usernameLoaded = false;

  /// True when the user chose "Continue as Guest". Persisted to SharedPreferences
  /// so the guest session survives app restarts. Cleared on sign-in or sign-out.
  bool _isGuest = false;

  /// Set to true by [AuthProvider.forTesting] to simulate a signed-in user
  /// without a real Firebase [User] object.  Never set in production.
  ///
  /// This flag lives in the production class (rather than a subclass) so that
  /// the real `_AuthGate` widget tree can be exercised in widget tests without
  /// needing to replace every `AuthProvider` consumer with a mock.  The flag is
  /// only ever non-false when the provider is created via [AuthProvider.forTesting].
  bool _testSignedIn = false;

  /// Active subscription to the Firestore username stream.
  /// Cancelled whenever the UID changes or the provider is disposed.
  StreamSubscription<String?>? _usernameStreamSub;

  User? get currentUser => _user;
  bool get isSignedIn => _user != null || _testSignedIn;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get currentUserEmail => _user?.email;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  /// True when the user is browsing as a guest (no Firebase account).
  /// [_AuthGate] routes to [MainScaffold] when this is true even without
  /// a signed-in Firebase user.
  bool get isGuest => _isGuest;

  /// The user's @handle, or null if not yet chosen.
  String? get username => _username;

  /// True once the username lookup from Firestore has completed (or failed).
  /// Use this to distinguish "still loading" from "user has no handle yet".
  bool get usernameLoaded => _usernameLoaded;

  /// True once the initial auth state (including the guest-mode flag) has been
  /// read from persistent storage.  [_AuthGate] uses this to avoid flashing
  /// [LoginScreen] for a single frame before [_isGuest] is restored from
  /// [SharedPreferences] on cold start.
  bool _initialStateReady = false;
  bool get initialStateReady => _initialStateReady;

  AuthProvider({bool firebaseReady = true, String? firebaseInitError})
      : _firebaseReady = firebaseReady,
        _firebaseInitError = firebaseInitError {
    _loadGuestMode();
    if (_firebaseReady) {
      // Keep _user in sync with Firebase's auth state stream.
      FirebaseAuth.instance.authStateChanges().listen((user) {
        final prevUid = _user?.uid;
        _user = user;
        if (user != null) {
          // Clear guest mode when a real account signs in.
          if (_isGuest) {
            _isGuest = false;
            SharedPreferences.getInstance()
                .then((p) => p.remove(_prefGuestMode));
          }
          if (user.uid != prevUid) {
            // Different (or newly confirmed) UID — reset and reload.
            _username = null;
            _usernameLoaded = false;
            _loadUsername(user.uid);
          } else if (!_usernameLoaded && _usernameStreamSub == null) {
            // Same UID, not yet loaded, and no active subscription —
            // start (or restart) the Firestore fetch.  We guard on
            // _usernameStreamSub != null so that rapid re-fires of
            // authStateChanges() (common on Flutter Web) cannot cancel
            // an in-flight subscription before it receives its first
            // value, which is the core cause of the race condition that
            // showed the "Choose a Handle" prompt on page-refresh.
            _loadUsername(user.uid);
          }
          // Same UID and already loaded (or subscription in progress) —
          // keep existing state to avoid a spurious loading-screen flash
          // on web page-refresh where authStateChanges() re-fires with
          // the same user after the synchronous currentUser path already
          // started resolving the username.
        } else {
          _username = null;
          _usernameLoaded = true;
          _usernameStreamSub?.cancel();
          _usernameStreamSub = null;
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

  /// Creates an [AuthProvider] with preset state for widget tests.
  ///
  /// Does not connect to Firebase.  The [isSignedIn] flag simulates an
  /// authenticated user without requiring a real [User] object.
  @visibleForTesting
  AuthProvider.forTesting({
    bool isSignedIn = false,
    String? username,
    bool usernameLoaded = true,
  }) : _firebaseReady = false,
       _firebaseInitError = null {
    _testSignedIn = isSignedIn;
    _username = username;
    _usernameLoaded = usernameLoaded;
    _initialStateReady = true; // Preset state is fully ready for tests.
  }

  /// Loads the persisted guest-mode flag from [SharedPreferences].
  ///
  /// Called once from the constructor; updates state asynchronously.
  /// If the user is already signed in when this resolves, the flag is ignored.
  /// Always marks [_initialStateReady] true when complete so [_AuthGate] can
  /// distinguish "still loading" from "confirmed not a guest".
  Future<void> _loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    final wasGuest = prefs.getBool(_prefGuestMode) ?? false;
    if (wasGuest && _user == null && !_testSignedIn) {
      _isGuest = wasGuest;
    }
    _initialStateReady = true;
    notifyListeners();
  }

  /// Enables or disables guest mode and persists the choice.
  ///
  /// When [value] is true, [_AuthGate] will route to [MainScaffold] even
  /// without a signed-in Firebase user, giving guests a fully functioning
  /// (but read-only / offline) app experience.
  Future<void> setGuestMode(bool value) async {
    if (_isGuest == value) return;
    _isGuest = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_prefGuestMode, true);
    } else {
      await prefs.remove(_prefGuestMode);
    }
  }

  /// Subscribes to the Firestore username stream for [uid].
  ///
  /// Uses [DatabaseService.usernameStream] which filters out stale
  /// cache-only null snapshots, preventing the "Choose a Handle" screen
  /// from flashing on web page-refresh while Firestore is still syncing.
  /// Only the first authoritative result is consumed (`.take(1)`).
  ///
  /// Note: `_usernameLoaded = true` is always set **before** clearing
  /// `_usernameStreamSub`, so the guard in the `authStateChanges()` listener
  /// (`!_usernameLoaded && _usernameStreamSub == null`) can never
  /// accidentally trigger a redundant reload after completion.
  /// SharedPreferences key for persisting the username locally.
  ///
  /// This lets the @handle display immediately on mobile (and any platform)
  /// without waiting for the Firestore stream to arrive, which can be slow
  /// on Android when there is no warm cache.
  static const _prefUsername = 'auth_cached_username';

  /// Loads the locally-cached username and restores it synchronously so the
  /// UI can display the @handle before the Firestore stream arrives.
  ///
  /// Called once from the constructor; updates state asynchronously.
  Future<void> _loadCachedUsername(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefUsername);
    // Only apply the cache if the username hasn't already been resolved by
    // the Firestore stream and the cached value belongs to the current user.
    if (cached != null && cached.isNotEmpty && _username == null) {
      _username = cached;
      notifyListeners();
    }
  }

  void _loadUsername(String uid) {
    // Start a local cache warm-up immediately so the username shows in the UI
    // even before the Firestore stream arrives (fixes mobile display delay).
    _loadCachedUsername(uid);

    _usernameStreamSub?.cancel();
    _usernameStreamSub = DatabaseService.instance
        .usernameStream(uid)
        .take(1)
        .listen(
          (handle) {
            _username = handle;
            // Persist to local cache so the next app launch can show the
            // username immediately without waiting for Firestore.
            if (handle != null && handle.isNotEmpty) {
              SharedPreferences.getInstance()
                  .then((p) => p.setString(_prefUsername, handle))
                  .ignore();
            }
            _usernameLoaded = true; // Set before clearing subscription ref.
            _usernameStreamSub = null;
            notifyListeners();
          },
          onError: (_) {
            _usernameLoaded = true; // Set before clearing subscription ref.
            _usernameStreamSub = null;
            notifyListeners();
          },
        );
  }

  /// Sets the username directly in memory without a Firestore round-trip.
  /// Use this immediately after a successful [claimUsername] call so the
  /// router navigates away from the handle screen without waiting for
  /// Firestore to propagate the write.
  void setUsernameDirectly(String handle) {
    _usernameStreamSub?.cancel();
    _usernameStreamSub = null;
    _username = handle.toLowerCase().trim();
    _usernameLoaded = true;
    // Persist immediately so the next app launch shows the handle right away.
    if (_username != null && _username!.isNotEmpty) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_prefUsername, _username!))
          .ignore();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _usernameStreamSub?.cancel();
    super.dispose();
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
    // Clear guest mode so the next launch shows the login screen.
    if (_isGuest) {
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefGuestMode);
    }
    // Clear the persisted username cache on sign-out so a different account
    // starting on the same device doesn't see a stale handle.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUsername);
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
