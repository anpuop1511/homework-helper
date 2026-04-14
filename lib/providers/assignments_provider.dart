import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../services/database_service.dart';
import 'user_provider.dart';

/// XP awarded when an assignment is marked complete.
const int _xpPerAssignment = 25;

/// Coins awarded when an assignment is marked complete.
const int _coinsPerAssignment = 10;

/// Season XP awarded when an assignment is marked complete.
const int _seasonXpPerAssignment = 20;

/// Manages the list of assignments and notifies listeners on changes.
///
/// When a Firebase UID is available (via [setUid]) the provider subscribes to
/// a real-time Firestore stream and mirrors all mutations to the cloud.
/// Without a UID it operates entirely in memory (guest / offline mode).
class AssignmentsProvider extends ChangeNotifier {
  UserProvider? _userProvider;

  String? _uid;
  StreamSubscription<List<Assignment>>? _sub;
  final List<Assignment> _assignments = [];

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
      // Guest mode: clear any existing data.
      _assignments.clear();
      notifyListeners();
      return;
    }

    // Cloud mode: subscribe to Firestore and mirror changes locally.
    final stream = DatabaseService.instance.assignmentsStream(uid);
    _sub = stream.listen(
      (cloudAssignments) {
        _assignments
          ..clear()
          ..addAll(cloudAssignments);
        notifyListeners();
      },
      onError: (_) {
        // Firestore unavailable — keep the current in-memory list.
      },
    );
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
  ///
  /// Rewards (XP / Coins / Season XP) are awarded only the *first* time an
  /// assignment is checked off.  Once [Assignment.rewardsClaimed] is true,
  /// unchecking and re-checking yields no further rewards, preventing farming.
  void toggleComplete(String id) {
    final idx = _assignments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final wasCompleted = _assignments[idx].isCompleted;
      _assignments[idx].isCompleted = !wasCompleted;
      // Award rewards only on the very first completion.
      if (!wasCompleted && !_assignments[idx].rewardsClaimed) {
        _assignments[idx].rewardsClaimed = true;
        _userProvider?.awardXp(_xpPerAssignment);
        _userProvider?.awardCoins(_coinsPerAssignment);
        _userProvider?.addSeasonXp(_seasonXpPerAssignment);
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
