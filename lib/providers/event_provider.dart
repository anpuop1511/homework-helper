import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_service.dart';

/// The state the limited-time event is currently in.
enum EventState { upcoming, active, ended }

/// Manages the May 2026 "Pencil Sharpener" XP event.
///
/// Event window: May 3 - May 15, 2026 (local time, inclusive).
/// Progress is based on XP earned from assignment completions recorded via
/// [recordAssignmentCompletion].
class EventProvider extends ChangeNotifier {
  static const String eventId = 'pencil_sharpener_2026_05';

  static final DateTime _eventStart = DateTime(2026, 5, 3);
  static final DateTime _eventEnd = DateTime(2026, 5, 16); // exclusive

  /// Milestones (1-indexed): 1000 XP, 2000 XP, 3000 XP.
  static const List<int> milestoneXp = [0, 1000, 2000, 3000];

  /// Weekend double-XP bonus cap per day.
  static const int weekendBonusDailyCap = 500;

  // ── Persistence keys ───────────────────────────────────────────────────

  static const _prefTotalXp = 'event_may_total_xp';
  static const _prefClaimed = 'event_may_claimed_milestones';
  static const _prefCountedIds = 'event_may_counted_assignment_ids';
  static const _prefWeekendBonusByDay = 'event_may_weekend_bonus_by_day';

  // ── State ───────────────────────────────────────────────────────────────

  int _totalXp = 0;
  final Set<int> _claimedMilestones = {};
  final Set<String> _countedAssignmentIds = {};
  final Map<String, int> _weekendBonusByDay = {};
  String? _uid;

  // ── Getters ─────────────────────────────────────────────────────────────

  int get totalXpDuringEvent => _totalXp;

  /// Backward-compatible alias used by existing UI copy.
  int get totalCompletedDuringEvent => _totalXp;

  Set<int> get claimedMilestones => Set.unmodifiable(_claimedMilestones);

  /// Backward-compatible alias for existing screens.
  Set<int> get claimedTiers => Set.unmodifiable(_claimedMilestones);

  EventState get state {
    final now = DateTime.now();
    if (now.isBefore(_eventStart)) return EventState.upcoming;
    if (now.isBefore(_eventEnd)) return EventState.active;
    return EventState.ended;
  }

  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(_eventStart)) return Duration.zero;
    return _eventStart.difference(now);
  }

  int get highestReachedMilestone {
    for (int m = 3; m >= 1; m--) {
      if (_totalXp >= milestoneXp[m]) return m;
    }
    return 0;
  }

  /// Backward-compatible alias for older screen code.
  int get highestReachedTier => highestReachedMilestone;

  int get currentWorkingMilestone {
    final reached = highestReachedMilestone;
    return reached < 3 ? reached + 1 : 3;
  }

  int get progressToCurrentMilestone {
    if (highestReachedMilestone >= 3) return milestoneXp[3];
    return _totalXp;
  }

  int get currentMilestoneGoal => milestoneXp[currentWorkingMilestone];

  bool isMilestoneReached(int milestone) {
    if (milestone < 1 || milestone > 3) return false;
    return _totalXp >= milestoneXp[milestone];
  }

  /// Backward-compatible alias used by older event UI.
  bool isTierReached(int tier) => isMilestoneReached(tier);

  bool isMilestoneClaimed(int milestone) => _claimedMilestones.contains(milestone);

  /// Backward-compatible alias used by older event UI.
  bool isTierClaimed(int tier) => _claimedMilestones.contains(tier);

  int weekendBonusUsedOn(DateTime day) {
    return _weekendBonusByDay[_dayKey(day)] ?? 0;
  }

  int get weekendBonusUsedToday => weekendBonusUsedOn(DateTime.now());

  // ── Constructor / init ──────────────────────────────────────────────────

  EventProvider() {
    _loadLocal();
  }

  // ── UID / cloud sync ────────────────────────────────────────────────────

  Future<void> setUid(String? uid) async {
    _uid = uid;
    if (uid == null) {
      await _loadLocal();
      return;
    }
    try {
      await _loadFromCloud(uid);
    } catch (_) {
      // Cloud unavailable; local state remains usable.
    }
  }

  Future<void> _loadFromCloud(String uid) async {
    final data = await DatabaseService.instance.getEventData(uid, eventId);
    if (data == null) return;

    final cloudTotalXp = (data['totalXp'] as int?) ?? (data['total'] as int?) ?? 0;
    final cloudClaimed =
      (data['claimedMilestones'] as List?)?.cast<int>() ??
        (data['claimed'] as List?)?.cast<int>() ??
        [];
    final cloudCounted =
      (data['countedAssignmentIds'] as List?)?.cast<String>() ??
        (data['countedIds'] as List?)?.cast<String>() ??
        [];
    final cloudWeekendRaw = data['weekendBonusByDay'] as Map<String, dynamic>?;

    if (cloudTotalXp > _totalXp) {
      _totalXp = cloudTotalXp;
    }
    _claimedMilestones.addAll(cloudClaimed);
    _countedAssignmentIds.addAll(cloudCounted);
    if (cloudWeekendRaw != null) {
      cloudWeekendRaw.forEach((k, v) {
        final parsed = v is int ? v : int.tryParse(v.toString()) ?? 0;
        final current = _weekendBonusByDay[k] ?? 0;
        if (parsed > current) {
          _weekendBonusByDay[k] = parsed;
        }
      });
    }

    notifyListeners();
    await _saveLocal();
  }

  Future<void> _syncToCloud() async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.saveEventData(
        uid: _uid!,
        eventId: eventId,
        total: _totalXp,
        claimedTiers: _claimedMilestones.toList(),
        countedIds: _countedAssignmentIds.toList(),
      );
    } catch (_) {
      // Cloud write failed; local progress is still saved.
    }
  }

  // ── Local persistence ────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _totalXp = prefs.getInt(_prefTotalXp) ?? 0;

    final claimedRaw = prefs.getStringList(_prefClaimed) ?? [];
    _claimedMilestones
      ..clear()
      ..addAll(claimedRaw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0));

    final countedRaw = prefs.getStringList(_prefCountedIds) ?? [];
    _countedAssignmentIds
      ..clear()
      ..addAll(countedRaw);

    final weekendRaw = prefs.getStringList(_prefWeekendBonusByDay) ?? [];
    _weekendBonusByDay
      ..clear()
      ..addAll(_decodeMap(weekendRaw));

    notifyListeners();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTotalXp, _totalXp);
    await prefs.setStringList(
      _prefClaimed,
      _claimedMilestones.map((m) => m.toString()).toList(),
    );
    await prefs.setStringList(_prefCountedIds, _countedAssignmentIds.toList());
    await prefs.setStringList(_prefWeekendBonusByDay, _encodeMap(_weekendBonusByDay));
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Records XP from an assignment completion.
  ///
  /// - Counts only while event is active.
  /// - Counts each assignment ID once.
  /// - Applies weekend double-XP bonus with a 500 bonus XP/day cap.
  void recordAssignmentCompletion(String assignmentId, {int baseXp = 25}) {
    if (state != EventState.active) return;
    if (_countedAssignmentIds.contains(assignmentId)) return;
    if (baseXp <= 0) return;

    _countedAssignmentIds.add(assignmentId);

    int bonus = 0;
    final now = DateTime.now();
    if (_isWeekend(now)) {
      final key = _dayKey(now);
      final used = _weekendBonusByDay[key] ?? 0;
      final remaining = (weekendBonusDailyCap - used).clamp(0, weekendBonusDailyCap);
      bonus = remaining > 0 ? baseXp.clamp(0, remaining) : 0;
      _weekendBonusByDay[key] = used + bonus;
    }

    _totalXp += (baseXp + bonus);

    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  bool claimMilestone(int milestone) {
    if (!isMilestoneReached(milestone)) return false;
    if (isMilestoneClaimed(milestone)) return false;
    _claimedMilestones.add(milestone);
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    return true;
  }

  /// Backward-compatible alias used by older event UI.
  bool claimTier(int tier) => claimMilestone(tier);

  Future<void> resetForTesting() async {
    _totalXp = 0;
    _claimedMilestones.clear();
    _countedAssignmentIds.clear();
    _weekendBonusByDay.clear();
    notifyListeners();
    await _saveLocal();
    await _syncToCloud();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static bool _isWeekend(DateTime dt) =>
      dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

  static String _dayKey(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static List<String> _encodeMap(Map<String, int> map) {
    return map.entries.map((e) => '${e.key}=${e.value}').toList();
  }

  static Map<String, int> _decodeMap(List<String> rows) {
    final out = <String, int>{};
    for (final row in rows) {
      final split = row.split('=');
      if (split.length != 2) continue;
      out[split[0]] = int.tryParse(split[1]) ?? 0;
    }
    return out;
  }
}
