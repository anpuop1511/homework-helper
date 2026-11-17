import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../models/assignment_template.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/due_date.dart' as due;
import 'user_provider.dart';
import 'event_provider.dart';

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
///
/// Also owns the recurring assignment templates (Dec feature drop): a
/// template spawns one assignment on its weekday, and every pending
/// assignment gets day-before + 1-hour deadline reminders via
/// [NotificationService] (which previously existed but was never called).
class AssignmentsProvider extends ChangeNotifier {
  UserProvider? _userProvider;
  EventProvider? _eventProvider;

  String? _uid;
  StreamSubscription<List<Assignment>>? _sub;
  StreamSubscription<List<AssignmentTemplate>>? _templatesSub;
  final List<Assignment> _assignments = [];
  final List<AssignmentTemplate> _templates = [];

  /// True once the assignments Firestore stream has delivered at least once
  /// (or immediately in guest mode, where the in-memory list is the truth).
  /// Template spawning waits for this so it never duplicates an assignment
  /// that is still in flight from the cloud.
  bool _assignmentsLoaded = false;

  List<Assignment> get assignments => List.unmodifiable(_assignments);

  List<AssignmentTemplate> get templates => List.unmodifiable(_templates);

  int get pendingCount => _assignments.where((a) => !a.isCompleted).length;

  /// Called by [ChangeNotifierProxyProvider] to inject [UserProvider].
  void updateUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  /// Called by [ChangeNotifierProxyProvider] to inject [EventProvider].
  void updateEventProvider(EventProvider eventProvider) {
    _eventProvider = eventProvider;
  }

  /// Maps a string assignment id to the small int [NotificationService]
  /// needs for an Android notification id.  Ids created by the app are
  /// epoch-millis strings and parse directly; anything else falls back to
  /// the hash, masked to < 2^24 so both reminder offsets stay in int32.
  /// Stable for every real id (millis strings parse identically every run).
  @visibleForTesting
  static int notificationIdFor(String id) {
    final parsed = int.tryParse(id);
    final raw = parsed ?? id.hashCode;
    return raw & 0x00ffffff;
  }

  /// Switches between guest mode (null) and cloud-backed mode (uid).
  Future<void> setUid(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;

    // Cancel any existing Firestore subscriptions.
    await _sub?.cancel();
    _sub = null;
    await _templatesSub?.cancel();
    _templatesSub = null;

    if (uid == null) {
      // Guest mode: clear any existing data.
      _assignments.clear();
      _templates.clear();
      _assignmentsLoaded = true;
      notifyListeners();
      return;
    }

    _assignmentsLoaded = false;

    // Cloud mode: subscribe to Firestore and mirror changes locally.
    final stream = DatabaseService.instance.assignmentsStream(uid);
    _sub = stream.listen(
      (cloudAssignments) {
        _assignments
          ..clear()
          ..addAll(cloudAssignments);
        _assignmentsLoaded = true;
        _maybeSpawnDueTemplates();
        notifyListeners();
      },
      onError: (_) {
        // Firestore unavailable — keep the current in-memory list.
      },
    );

    final templatesStream = DatabaseService.instance.templatesStream(uid);
    _templatesSub = templatesStream.listen(
      (cloudTemplates) {
        _templates
          ..clear()
          ..addAll(cloudTemplates);
        _maybeSpawnDueTemplates();
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
    if (!assignment.isCompleted) {
      _scheduleReminders(assignment);
    }
  }

  /// Toggles the completion state of an assignment by [id].
  ///
  /// Rewards (XP / Coins / Season XP) are awarded only the *first* time an
  /// assignment is checked off.  Once [Assignment.rewardsClaimed] is true,
  /// unchecking and re-checking yields no further rewards, preventing farming.
  ///
  /// Deadline reminders are cancelled on completion and re-scheduled if the
  /// assignment is unchecked again.
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
        // Notify the May event provider so it can award event XP progress.
        _eventProvider?.recordAssignmentCompletion(
          _assignments[idx].id,
          baseXp: _xpPerAssignment,
        );
      }
      notifyListeners();
      if (_uid != null) {
        DatabaseService.instance.saveAssignment(_uid!, _assignments[idx]);
      }
      if (_assignments[idx].isCompleted) {
        NotificationService.instance
            .cancelDeadlineReminder(notificationIdFor(id));
      } else {
        _scheduleReminders(_assignments[idx]);
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
    NotificationService.instance.cancelDeadlineReminder(notificationIdFor(id));
  }

  // ── Deadline reminders ─────────────────────────────────────────────────

  /// Schedules the day-before + 1-hour reminders for a pending assignment.
  /// Due dates are date-only, so the deadline passed in is the END of the
  /// due day (23:59) — the 1-hour reminder then fires on the due day
  /// itself, not at 23:00 the night before.
  void _scheduleReminders(Assignment assignment) {
    NotificationService.instance.scheduleDeadlineReminders(
      assignmentId: notificationIdFor(assignment.id),
      title: assignment.title,
      deadline: due.endOfDueDay(assignment.dueDate),
    );
  }

  // ── Recurring assignment templates ─────────────────────────────────────

  /// Adds a template, persists it, and spawns today's assignment from it
  /// immediately if today is its weekday.
  void addTemplate(AssignmentTemplate template) {
    _templates.add(template);
    notifyListeners();
    if (_uid != null) {
      DatabaseService.instance.saveTemplate(_uid!, template);
    }
    _maybeSpawnDueTemplates();
  }

  /// Deletes a template.  Assignments it already spawned are left alone.
  void deleteTemplate(String templateId) {
    _templates.removeWhere((t) => t.id == templateId);
    notifyListeners();
    if (_uid != null) {
      DatabaseService.instance.deleteTemplate(_uid!, templateId);
    }
  }

  /// Public entry point for the Home screen (and anything else that opens
  /// while the app is already running): spawn any template assignments due
  /// today.  Safe to call repeatedly — spawning is idempotent.
  void checkAndSpawnTemplates() => _maybeSpawnDueTemplates();

  /// Spawns one assignment per template whose weekday is today.
  ///
  /// A template spawns only when ALL of these hold:
  ///   - the assignments list is loaded (cloud snapshot arrived, or guest),
  ///   - today is the template's weekday,
  ///   - the template has not already spawned today ([lastSpawnedDate]), and
  ///   - no assignment from this template is already due today
  ///     (covers the one-off created alongside the template in AddTaskSheet,
  ///     and stream replays).
  ///
  /// No backfill: a weekday the app was never opened on is skipped, never
  /// spawned late.
  void _maybeSpawnDueTemplates() {
    if (!_assignmentsLoaded || _templates.isEmpty) return;
    final now = DateTime.now();
    final today = due.dateOnly(now);
    for (final template in List<AssignmentTemplate>.of(_templates)) {
      if (template.weekday != today.weekday) continue;
      if (template.lastSpawnedDate != null &&
          due.dateOnly(template.lastSpawnedDate!) == today) {
        continue;
      }
      final alreadySpawned = _assignments.any((a) =>
          a.templateId == template.id && due.isDueOn(a.dueDate, today));
      if (alreadySpawned) continue;

      final spawned = Assignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: template.title,
        subject: template.subject,
        dueDate: today,
        estimatedMinutes: template.estimatedMinutes,
        templateId: template.id,
      );
      add(spawned);

      final updated =
          template.copyWith(lastSpawnedDate: today);
      final idx = _templates.indexWhere((t) => t.id == template.id);
      if (idx != -1) _templates[idx] = updated;
      if (_uid != null) {
        DatabaseService.instance.saveTemplate(_uid!, updated);
      }
    }
  }

  /// Spawns a set of dummy test assignments for QA purposes.
  ///
  /// Creates five fake homework tasks across different subjects so the
  /// anti-farming logic and completion flow can be tested end-to-end.
  void spawnTestAssignments() {
    final now = DateTime.now();
    final base = now.millisecondsSinceEpoch;
    final testAssignments = [
      Assignment(
        id: 'qa_${base}_1',
        title: '[QA] Math Homework',
        subject: Subject.math,
        dueDate: now.add(const Duration(days: 1)),
      ),
      Assignment(
        id: 'qa_${base}_2',
        title: '[QA] Science Lab Report',
        subject: Subject.science,
        dueDate: now.add(const Duration(days: 2)),
      ),
      Assignment(
        id: 'qa_${base}_3',
        title: '[QA] History Essay',
        subject: Subject.history,
        dueDate: now.add(const Duration(days: 3)),
      ),
      Assignment(
        id: 'qa_${base}_4',
        title: '[QA] English Reading',
        subject: Subject.english,
        dueDate: now.add(const Duration(days: 1)),
      ),
      Assignment(
        id: 'qa_${base}_5',
        title: '[QA] Art Project',
        subject: Subject.art,
        dueDate: now.add(const Duration(days: 5)),
      ),
    ];
    for (final a in testAssignments) {
      add(a);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _templatesSub?.cancel();
    super.dispose();
  }
}
