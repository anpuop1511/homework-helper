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
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
      'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',
    ],
  );

  // ── Internal state ─────────────────────────────────────────────────────
  ClassroomAuthStatus _status = ClassroomAuthStatus.loading;
  String? _error;
  List<ClassroomCourse> _courses = [];
  List<ClassroomCoursework> _coursework = [];
  bool _coursesLoading = false;
  bool _courseworkLoading = false;
  String? _selectedCourseId;

  // ── Public getters ─────────────────────────────────────────────────────
  ClassroomAuthStatus get status => _status;
  String? get error => _error;
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

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasAuthorized = prefs.getBool(_kAuthorized) ?? false;

      if (!wasAuthorized) {
        _status = ClassroomAuthStatus.notAuthorized;
        notifyListeners();
        return;
      }

      // Try to silently restore the existing Google session.
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
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
    notifyListeners();

    try {
      // Sign out first so the user always sees the account-picker if they
      // have multiple Google accounts.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the consent screen.
        _status = ClassroomAuthStatus.notAuthorized;
        notifyListeners();
        return false;
      }

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
    } catch (e) {
      debugPrint('[ClassroomProvider] authorize error: $e');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAuthorized, false);
    _status = ClassroomAuthStatus.notAuthorized;
    _error = null;
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

  /// Returns auth headers for the current Google session, or `null` if the
  /// session has expired / been revoked.
  Future<Map<String, String>?> _authHeaders() async {
    try {
      final account = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently();
      if (account == null) return null;
      return await account.authHeaders;
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
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return 'No internet connection. Please check your network and retry.';
    }
    if (msg.contains('quota') || msg.contains('rate')) {
      return 'API quota exceeded. Please wait a moment and try again.';
    }
    if (msg.contains('cancel') || msg.contains('aborted')) {
      return 'Authorization was cancelled.';
    }
    if (msg.contains('sign_in_failed') || msg.contains('sign_in_canceled')) {
      return 'Google sign-in failed. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
