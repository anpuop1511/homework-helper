import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import '../firebase_options.dart';

/// Provides a single, canonical place for Firebase initialization.
///
/// [ensureInitialized] is **idempotent** — safe to call multiple times and
/// across Flutter hot restarts, where the Dart isolate is reset but the native
/// Android/iOS Firebase SDK remains initialized.
///
/// ## Why this helper exists
///
/// On Android, the `google-services.json` plugin can auto-initialize the
/// default Firebase app **before** Flutter's Dart layer starts.  If the Dart
/// layer then also calls `Firebase.initializeApp()`, the native SDK throws a
/// `[core/duplicate-app]` error.  The previous guard (`Firebase.apps.isEmpty`)
/// is not always sufficient because the Dart-side registry may still be empty
/// even when the native app is already initialized.
///
/// This helper resolves all three scenarios:
///   1. Normal cold start — Dart calls `initializeApp()` first → succeeds.
///   2. Native auto-init (Android google-services) — `duplicate-app` is
///      thrown but caught and treated as success.
///   3. Hot restart (dev) — Dart registry reset; same as scenario 1 or 2.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  // ── Cached result ──────────────────────────────────────────────────────

  /// The name of the default Firebase app, as defined by the Firebase SDK.
  static const String _defaultAppName = '[DEFAULT]';

  static bool _ready = false;
  static String? _error;
  static bool _attempted = false;

  /// True once Firebase has been successfully initialized (or was already
  /// initialized by the native SDK before Flutter started).
  static bool get isReady => _ready;

  /// The raw error string if initialization failed, or null on success.
  ///
  /// Displayed verbatim in the LoginScreen diagnostic box so failures are
  /// diagnosable without needing Android Studio.
  static String? get error => _error;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Ensures the default Firebase app is initialized exactly once.
  ///
  /// Calling this method multiple times is always safe:
  ///   - If the default app is already registered in the Dart layer the method
  ///     returns immediately without calling [Firebase.initializeApp].
  ///   - If [Firebase.initializeApp] throws `[core/duplicate-app]` (native
  ///     SDK race condition) the error is swallowed and Firebase is treated as
  ///     ready, because the app *is* initialized — just not through Dart.
  ///   - Any other exception is recorded in [error] and [isReady] stays
  ///     `false`, allowing the app to fall back to offline / guest-only mode.
  ///
  /// Returns `true` if Firebase is ready to use after this call.
  static Future<bool> ensureInitialized() async {
    // Fast path: default app already registered in the Dart layer.
    // Covers the case where ensureInitialized() is called more than once
    // within the same Dart isolate (e.g. during testing).
    if (Firebase.apps.any((app) => app.name == _defaultAppName)) {
      _ready = true;
      _attempted = true;
      debugPrint('[FirebaseBootstrap] Default app already initialized — reusing.');
      return true;
    }

    // Guard against re-entry within the same Dart isolate lifetime.
    if (_attempted) return _ready;
    _attempted = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
      debugPrint('[FirebaseBootstrap] Firebase initialized successfully.');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        // The native Android SDK (via google-services.json) already initialized
        // the default Firebase app before Flutter's Dart layer ran.  This can
        // also happen during Flutter hot restart.  Treat as success.
        _ready = true;
        debugPrint(
          '[FirebaseBootstrap] duplicate-app — native SDK already initialized '
          'Firebase before Flutter. Treating as success.',
        );
      } else {
        _error = e.toString();
        debugPrint('[FirebaseBootstrap] Firebase init failed (FirebaseException): $_error');
      }
    } catch (e) {
      // Placeholder firebase_options.dart (REPLACE_WITH_* keys) or any other
      // configuration error — the app will run in offline / guest-only mode.
      _error = e.toString();
      debugPrint('[FirebaseBootstrap] Firebase init failed: $_error');
    }

    return _ready;
  }

  // ── Test helpers ───────────────────────────────────────────────────────

  /// Resets cached state so unit tests start from a clean slate.
  ///
  /// **Never call this in production code.**
  @visibleForTesting
  static void resetForTesting() {
    _ready = false;
    _error = null;
    _attempted = false;
  }
}
