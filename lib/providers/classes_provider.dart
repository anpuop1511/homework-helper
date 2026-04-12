import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';
import '../services/database_service.dart';

/// Manages the user's persistent list of [SchoolClass] objects.
///
/// When a Firebase UID is set (via [setUid]) the provider subscribes to a
/// real-time Firestore stream under `users/{uid}/classes` and mirrors all
/// mutations to the cloud.  Without a UID it operates in memory only.
class ClassesProvider extends ChangeNotifier {
  String? _uid;
  StreamSubscription<List<SchoolClass>>? _sub;
  final List<SchoolClass> _classes = [];

  List<SchoolClass> get classes => List.unmodifiable(_classes);

  /// Called whenever the authenticated user changes (sign-in / sign-out).
  void setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _classes.clear();

    if (uid != null) {
      _sub = DatabaseService.instance
          .watchClasses(uid)
          .handleError((Object e) {
            // Firestore may be unavailable (offline, rules) — ignore silently.
            debugPrint('[ClassesProvider] Firestore error: $e');
          })
          .listen((list) {
            _classes
              ..clear()
              ..addAll(list);
            notifyListeners();
          });
    }
    notifyListeners();
  }

  /// Adds a new class.  If offline or UID is null, adds locally only until
  /// the next sync.
  Future<void> addClass(SchoolClass schoolClass) async {
    final uid = _uid;
    if (uid == null) {
      // Guest / offline — store in memory with a temporary ID.
      final temp = schoolClass.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}');
      _classes.add(temp);
      notifyListeners();
      return;
    }
    try {
      await DatabaseService.instance.addClass(uid, schoolClass);
      // The Firestore stream will deliver the update.
    } catch (e) {
      debugPrint('[ClassesProvider] addClass error: $e');
      // Fall back to local list so the UI stays responsive.
      final temp = schoolClass.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}');
      _classes.add(temp);
      notifyListeners();
    }
  }

  /// Updates an existing class.
  Future<void> updateClass(SchoolClass schoolClass) async {
    final uid = _uid;
    // Optimistic local update.
    final idx = _classes.indexWhere((c) => c.id == schoolClass.id);
    if (idx != -1) {
      _classes[idx] = schoolClass;
      notifyListeners();
    }
    if (uid == null) return;
    try {
      await DatabaseService.instance.updateClass(uid, schoolClass);
    } catch (e) {
      debugPrint('[ClassesProvider] updateClass error: $e');
    }
  }

  /// Deletes a class by ID.
  Future<void> deleteClass(String classId) async {
    final uid = _uid;
    // Optimistic local remove.
    _classes.removeWhere((c) => c.id == classId);
    notifyListeners();
    if (uid == null) return;
    try {
      await DatabaseService.instance.deleteClass(uid, classId);
    } catch (e) {
      debugPrint('[ClassesProvider] deleteClass error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
