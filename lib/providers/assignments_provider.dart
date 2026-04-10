import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../services/database_service.dart';
import 'user_provider.dart';

/// XP awarded when an assignment is marked complete.
const int _xpPerAssignment = 25;

/// Sample assignments shown in offline / guest mode.
List<Assignment> _sampleAssignments() => [
      Assignment(
        id: '1',
        title: 'Chapter 5 Algebra Problems',
        subject: Subject.math,
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Assignment(
        id: '2',
        title: 'Lab Report: Chemical Reactions',
        subject: Subject.science,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
      Assignment(
        id: '3',
        title: 'Essay: World War II Causes',
        subject: Subject.history,
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      Assignment(
        id: '4',
        title: 'Shakespeare: Romeo & Juliet Analysis',
        subject: Subject.english,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Assignment(
        id: '5',
        title: 'Watercolor Landscape Painting',
        subject: Subject.art,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Assignment(
        id: '6',
        title: 'Practice Scales — C Major',
        subject: Subject.music,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        isCompleted: true,
      ),
    ];

/// Manages the list of assignments and notifies listeners on changes.
///
/// When a Firebase UID is available (via [setUid]) the provider subscribes to
/// a real-time Firestore stream and mirrors all mutations to the cloud.
/// Without a UID it operates entirely in memory (guest / offline mode).
class AssignmentsProvider extends ChangeNotifier {
  UserProvider? _userProvider;

  String? _uid;
  StreamSubscription<List<Assignment>>? _sub;
  final List<Assignment> _assignments = _sampleAssignments();

  List<Assignment> get assignments => List.unmodifiable(_assignments);

  int get pendingCount => _assignments.where((a) => !a.isCompleted).length;

  /// Called by [ChangeNotifierProxyProvider] to inject [UserProvider].
  void updateUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  /// Switches between guest mode (null) and cloud-backed mode (uid).
  Future<void> setUid(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;

    // Cancel any existing Firestore subscription.
    await _sub?.cancel();
    _sub = null;

    if (uid == null) {
      // Guest mode: restore sample data.
      _assignments
        ..clear()
        ..addAll(_sampleAssignments());
      notifyListeners();
      return;
    }

    // Cloud mode: if there are no docs yet, seed with the local sample data.
    final stream = DatabaseService.instance.assignmentsStream(uid);
    bool firstEvent = true;
    _sub = stream.listen((cloudAssignments) async {
      if (firstEvent && cloudAssignments.isEmpty) {
        // Migrate the in-memory sample data to the cloud on first login.
        await DatabaseService.instance.bulkSaveAssignments(
          uid,
          List.of(_assignments),
        );
        firstEvent = false;
        return; // The migration triggers another stream event with real data.
      }
      firstEvent = false;
      _assignments
        ..clear()
        ..addAll(cloudAssignments);
      notifyListeners();
    });
  }

  /// Adds a new assignment and notifies listeners.
  void add(Assignment assignment) {
    _assignments.add(assignment);
    notifyListeners();
    if (_uid != null) {
      DatabaseService.instance.saveAssignment(_uid!, assignment);
    }
  }

  /// Toggles the completion state of an assignment by [id].
  /// Awards XP when an assignment is marked complete.
  void toggleComplete(String id) {
    final idx = _assignments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final wasCompleted = _assignments[idx].isCompleted;
      _assignments[idx].isCompleted = !wasCompleted;
      if (!wasCompleted) {
        _userProvider?.awardXp(_xpPerAssignment);
      }
      notifyListeners();
      if (_uid != null) {
        DatabaseService.instance.saveAssignment(_uid!, _assignments[idx]);
      }
    }
  }

  /// Deletes the assignment with the given [id].
  void delete(String id) {
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
    if (_uid != null) {
      DatabaseService.instance.deleteAssignment(_uid!, id);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
