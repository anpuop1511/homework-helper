import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ────────────────────────────────────────────────────────────────

/// A Google Classroom course.
class ClassroomCourse {
  final String id;
  final String name;
  final String? section;
  final String? description;
  final String? courseState;

  const ClassroomCourse({
    required this.id,
    required this.name,
    this.section,
    this.description,
    this.courseState,
  });

  factory ClassroomCourse.fromJson(Map<String, dynamic> json) {
    return ClassroomCourse(
      id: json['id'] as String,
      name: json['name'] as String? ?? '(No name)',
      section: json['section'] as String?,
      description: json['description'] as String?,
      courseState: json['courseState'] as String?,
    );
  }
}

/// A piece of coursework in a Google Classroom course.
class ClassroomCoursework {
  final String id;
  final String title;
  final String? description;
  final String? dueDateLabel;
  final String? workType;
  final String courseId;

  const ClassroomCoursework({
    required this.id,
    required this.title,
    required this.courseId,
    this.description,
    this.dueDateLabel,
    this.workType,
  });

  factory ClassroomCoursework.fromJson(
      Map<String, dynamic> json, String courseId) {
    String? dueLabel;
    final due = json['dueDate'] as Map<String, dynamic>?;
    if (due != null) {
      final y = due['year'];
      final m = due['month'];
      final d = due['day'];
      if (y != null && m != null && d != null) {
        dueLabel = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      }
    }
    return ClassroomCoursework(
      id: json['id'] as String,
      title: json['title'] as String? ?? '(No title)',
      description: json['description'] as String?,
      dueDateLabel: dueLabel,
      workType: json['workType'] as String?,
      courseId: courseId,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

/// The authorization status of the Classroom integration.
enum ClassroomAuthStatus {
  /// Status not yet loaded from storage.
  loading,

  /// Not authorized – user has not connected Google Classroom.
  notAuthorized,

  /// OAuth flow is in progress.
  authorizing,

  /// Authorized and ready to make Classroom API calls.
  authorized,

  /// A transient or permanent error occurred (see [ClassroomProvider.error]).
  error,
}

/// Manages the Google Classroom OAuth integration.
///
/// **Scope**: This provider is intentionally separate from the main Firebase
/// auth ([AuthProvider]).  It does **not** change the user's sign-in state
/// in the rest of the app; it only handles the Classroom-specific OAuth
/// consent grant and subsequent API calls.
///
/// State persisted to [SharedPreferences]:
/// - `classroom_authorized` (bool): whether the user has granted access.
///
/// Tokens are managed internally by the [GoogleSignIn] plugin.
class ClassroomProvider extends ChangeNotifier {
  // ── Shared-prefs keys ──────────────────────────────────────────────────
  static const _kAuthorized = 'classroom_authorized';

  // ── Google Sign-In (Classroom scopes only) ─────────────────────────────
  static final _googleSignIn = GoogleSignIn.instance;
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',
  ];

  // ── Internal state ─────────────────────────────────────────────────────
  ClassroomAuthStatus _status = ClassroomAuthStatus.loading;
  String? _error;
  // Raw exception detail surfaced only in debug builds for diagnostics.
  String? _diagnosticDetail;
  List<ClassroomCourse> _courses = [];
  List<ClassroomCoursework> _coursework = [];
  bool _coursesLoading = false;
  bool _courseworkLoading = false;
  String? _selectedCourseId;
  // Tracks the authenticated account (google_sign_in v7 removed currentUser).
  GoogleSignInAccount? _currentAccount;
  // Guards against calling initialize() more than once.
  bool _gsiInitialized = false;

  // ── Public getters ─────────────────────────────────────────────────────
  ClassroomAuthStatus get status => _status;
  String? get error => _error;
  /// Raw exception detail for diagnosing failures. Only non-null in debug
  /// builds; always null in release/profile mode.
  String? get diagnosticDetail => kDebugMode ? _diagnosticDetail : null;
  List<ClassroomCourse> get courses => List.unmodifiable(_courses);
  List<ClassroomCoursework> get coursework =>
      List.unmodifiable(_coursework);
  bool get coursesLoading => _coursesLoading;
  bool get courseworkLoading => _courseworkLoading;
  String? get selectedCourseId => _selectedCourseId;
  bool get isAuthorized => _status == ClassroomAuthStatus.authorized;

  ClassroomProvider() {
    _init();
  }

  // ── Initialization ─────────────────────────────────────────────────────

  /// Calls [GoogleSignIn.initialize] exactly once and wires up the
  /// authentication event stream to keep [_currentAccount] up to date.
  Future<void> _ensureGsiInitialized() async {
    if (_gsiInitialized) return;
    await _googleSignIn.initialize();
    _gsiInitialized = true;
    _googleSignIn.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentAccount = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentAccount = null;
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasAuthorized = prefs.getBool(_kAuthorized) ?? false;

      if (!wasAuthorized) {
        _status = ClassroomAuthStatus.notAuthorized;
        notifyListeners();
        return;
      }

      await _ensureGsiInitialized();

      // Try to silently restore the existing Google session.
      // attemptLightweightAuthentication returns Future<GoogleSignInAccount?>?
      // (nullable Future) – on platforms where it can't return immediately it
      // returns null and posts to the authenticationEvents stream instead.
      final future = _googleSignIn.attemptLightweightAuthentication();
      final account = future != null ? await future : null;
      if (account != null) {
        _currentAccount = account;
        _status = ClassroomAuthStatus.authorized;
      } else {
        // Token expired or revoked – clear stored flag.
        await prefs.setBool(_kAuthorized, false);
        _status = ClassroomAuthStatus.notAuthorized;
      }
    } catch (e) {
      debugPrint('[ClassroomProvider] init error: $e');
      _status = ClassroomAuthStatus.notAuthorized;
    }
    notifyListeners();
  }

  // ── Authorization ───────────────────────────────────────────────────────

  /// Initiates the Google OAuth consent flow for Classroom scopes.
  ///
  /// Returns `true` on success, `false` if the user cancelled, and sets
  /// [error] when an unexpected failure occurs.
  Future<bool> authorize() async {
    _status = ClassroomAuthStatus.authorizing;
    _error = null;
    _diagnosticDetail = null;
    notifyListeners();

    try {
      await _ensureGsiInitialized();

      // Sign out first so the user always sees the account-picker if they
      // have multiple Google accounts.
      await _googleSignIn.signOut();
      _currentAccount = null;

      // authenticate() shows the account-picker and (when scopeHint is
      // provided) may also show the OAuth consent screen inline on platforms
      // that support a combined flow (e.g. Android).
      final account = await _googleSignIn
          .authenticate(scopeHint: _scopes)
          .timeout(const Duration(seconds: 15));
      _currentAccount = account;

      // Explicitly request Classroom scopes in case the platform deferred
      // authorization to a separate step.
      await account.authorizationClient
          .authorizeScopes(_scopes)
          .timeout(const Duration(seconds: 15));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAuthorized, true);
      _status = ClassroomAuthStatus.authorized;
      _courses = [];
      _coursework = [];
      _selectedCourseId = null;
      notifyListeners();

      // Pre-fetch courses immediately after authorization.
      await fetchCourses();
      return true;
    } on TimeoutException {
      debugPrint('[ClassroomProvider] authorize timed out');
      _diagnosticDetail = 'TimeoutException after 15 s';
      _error = 'Sign-in timed out. Please check your internet connection or '
          'verify your app\'s Google Cloud configuration (missing Web Client ID).';
      _status = ClassroomAuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[ClassroomProvider] authorize error: $e');
      _diagnosticDetail = e.toString();

      // Recoverable credential failure (BadAuthentication / long-lived token
      // gone): call disconnect() to fully clear the stale GMS session so the
      // next authorize() attempt starts from a clean state instead of looping.
      if (_isRecoverableBadAuth(e)) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
        _currentAccount = null;
      }

      _error = _friendlyError(e);
      _status = ClassroomAuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Disconnects the Google Classroom account and revokes access.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Best-effort revoke.
    }
    _currentAccount = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAuthorized, false);
    _status = ClassroomAuthStatus.notAuthorized;
    _error = null;
    _diagnosticDetail = null;
    _courses = [];
    _coursework = [];
    _selectedCourseId = null;
    notifyListeners();
  }

  // ── Data fetching ───────────────────────────────────────────────────────

  /// Fetches the authenticated user's Classroom courses.
  Future<void> fetchCourses() async {
    if (!isAuthorized) return;
    _coursesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authHeaders();
      if (headers == null) {
        _handleSessionExpired();
        return;
      }
      final uri = Uri.https(
        'classroom.googleapis.com',
        '/v1/courses',
        {'courseStates': 'ACTIVE', 'pageSize': '50'},
      );
      final response = await http.get(uri, headers: headers);
      _handleRateLimit(response);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['courses'] as List<dynamic>? ?? [];
        _courses = list
            .map((e) => ClassroomCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        _error = null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _handleSessionExpired();
        return;
      } else {
        _error = 'Failed to load courses (${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('[ClassroomProvider] fetchCourses error: $e');
      _error = _friendlyError(e);
    } finally {
      _coursesLoading = false;
      notifyListeners();
    }
  }

  /// Fetches coursework for [courseId] (or [_selectedCourseId] when null).
  Future<void> fetchCoursework({String? courseId}) async {
    if (!isAuthorized) return;
    final cid = courseId ?? _selectedCourseId;
    if (cid == null) return;

    _selectedCourseId = cid;
    _courseworkLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authHeaders();
      if (headers == null) {
        _handleSessionExpired();
        return;
      }
      final uri = Uri.https(
        'classroom.googleapis.com',
        '/v1/courses/$cid/courseWork',
        {'pageSize': '50'},
      );
      final response = await http.get(uri, headers: headers);
      _handleRateLimit(response);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['courseWork'] as List<dynamic>? ?? [];
        _coursework = list
            .map((e) =>
                ClassroomCoursework.fromJson(e as Map<String, dynamic>, cid))
            .toList();
        _error = null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _handleSessionExpired();
        return;
      } else {
        _error = 'Failed to load coursework (${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('[ClassroomProvider] fetchCoursework error: $e');
      _error = _friendlyError(e);
    } finally {
      _courseworkLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Returns `true` when [e] represents a recoverable device-level credential
  /// failure (e.g. Google Play Services `BAD_AUTHENTICATION` /
  /// "Long live credential not available").
  static bool _isRecoverableBadAuth(Object e) {
    final lower = e.toString().toLowerCase();
    return lower.contains('badauthentication') ||
        lower.contains('bad_authentication') ||
        lower.contains('long live credential not available') ||
        lower.contains('long_live_credential') ||
        lower.contains('userrecoverable');
  }

  /// Returns auth headers for the current Google session, or `null` if the
  /// session has expired / been revoked.
  Future<Map<String, String>?> _authHeaders() async {
    try {
      var account = _currentAccount;
      if (account == null) {
        // Try to restore the session silently.
        final future = _googleSignIn.attemptLightweightAuthentication();
        if (future == null) return null;
        account = await future;
        if (account == null) return null;
        _currentAccount = account;
      }
      final auth =
          await account.authorizationClient.authorizationForScopes(_scopes);
      if (auth == null) return null;
      return {'Authorization': 'Bearer ${auth.accessToken}'};
    } catch (_) {
      return null;
    }
  }

  void _handleSessionExpired() {
    SharedPreferences.getInstance().then((p) => p.setBool(_kAuthorized, false));
    _status = ClassroomAuthStatus.error;
    _error =
        'Your Google Classroom session has expired or been revoked. '
        'Please re-authorize to continue.';
    _coursesLoading = false;
    _courseworkLoading = false;
    notifyListeners();
  }

  /// Checks for HTTP 429 (rate-limit) and surfaces a user-friendly message.
  void _handleRateLimit(http.Response response) {
    if (response.statusCode == 429) {
      throw Exception(
          'Google Classroom API quota exceeded. Please wait a moment and try again.');
    }
  }

  static String _friendlyError(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();

    // Recoverable device-level credential failure: GMS reports
    // BAD_AUTHENTICATION / "Long live credential not available".
    // The user must re-add or re-authenticate their Google account on the
    // device before the app can obtain a fresh token.
    if (_isRecoverableBadAuth(e)) {
      return 'Your Google account session is no longer valid on this device. '
          'Go to Android Settings → Accounts → Google, remove and re-add your '
          'account (or sign out and back in), then try connecting again.';
    }

    // OAuth / developer misconfiguration: SHA certificate mismatch or the app
    // is not registered correctly in Google Cloud Console.
    // google_sign_in surfaces this as ApiException code 10 (DEVELOPER_ERROR).
    if (lower.contains('developer_error') ||
        lower.contains('apiexception: 10') ||
        RegExp(r'apiexception:?\s*10\b').hasMatch(lower)) {
      return 'OAuth configuration error. The app\'s signing certificate may '
          'not match your Google Cloud project. Check your SHA fingerprints '
          'in the Cloud Console and ensure the Classroom API is enabled.';
    }

    // User voluntarily cancelled the sign-in picker or consent screen.
    // google_sign_in v7 uses sign_in_canceled; older SDKs used sign_in_cancelled.
    if (lower.contains('sign_in_canceled') ||
        lower.contains('sign_in_cancelled') ||
        lower.contains('12500') ||
        lower.contains('cancel') ||
        lower.contains('aborted')) {
      return 'Sign-in was cancelled. Tap "Try Again" whenever you\'re ready.';
    }

    // Network / connectivity issues.
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('unreachable') ||
        lower.contains('timeout')) {
      return 'No internet connection. Please check your network and retry.';
    }

    // Access denied, insufficient OAuth scopes, or the Classroom API is not
    // enabled on the Google Cloud project.
    if (lower.contains('access_denied') ||
        lower.contains('insufficient_scope') ||
        lower.contains('insufficient scope') ||
        lower.contains('forbidden') ||
        lower.contains('service_disabled') ||
        lower.contains('not authorized') ||
        lower.contains('permission')) {
      return 'Access denied. Make sure the Google Classroom API is enabled '
          'in your Google Cloud project and the required permissions are '
          'granted.';
    }

    // API quota / rate limit.
    if (lower.contains('quota') || lower.contains('rate')) {
      return 'API quota exceeded. Please wait a moment and try again.';
    }

    // Unknown / fallback.
    return 'Connection failed. Please try again or contact support if the '
        'issue persists.';
  }
}
