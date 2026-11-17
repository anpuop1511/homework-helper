import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_service.dart';

/// The state the limited-time event is currently in.
enum EventState { upcoming, active, ended }

/// What kind of cosmetic a milestone grants.
enum EventRewardKind { badge, profileFrame, nameplate }

/// One XP milestone of a limited-time event.
class EventMilestone {
  /// XP needed to reach this milestone.
  final int xp;

  /// Cosmetic ID granted on claim (see [EventRewardKind]).
  final String cosmeticId;

  final EventRewardKind kind;

  /// Tile title, e.g. `'1000 XP · Cocoa Badge'`.
  final String title;

  final String subtitle;

  /// Emoji shown on the milestone tile.
  final String emoji;

  const EventMilestone({
    required this.xp,
    required this.cosmeticId,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });
}

/// A parameterised limited-time XP event.
///
/// To ship a new event, add a definition below and point
/// [EventProvider.current] at it. Nothing else in the provider is
/// event-specific: the window, milestones, rewards and persistence keys all
/// derive from the definition, so progress for one event can never leak into
/// another (Firestore doc id and SharedPreferences keys both embed
/// [EventDefinition.id]).
class EventDefinition {
  /// Stable id, also used as the Firestore `events/{id}` doc id.
  final String id;

  /// Display name, e.g. `'Cocoa Clash'`.
  final String name;

  /// Window start (local time, inclusive).
  final DateTime start;

  /// Window end (local time, exclusive).
  final DateTime end;

  /// Human-readable window, e.g. `'Dec 1 – 25'`.
  final String windowLabel;

  /// Milestones in ascending XP order (1-indexed for the UI).
  final List<EventMilestone> milestones;

  /// Weekend double-XP bonus cap per day.
  final int weekendBonusDailyCap;

  const EventDefinition({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.windowLabel,
    required this.milestones,
    this.weekendBonusDailyCap = 500,
  });
}

/// May 2026 "Pencil Sharpener" event — kept for reference only.
/// Its progress lives under its own id/keys and is not migrated into the
/// current event; see [EventProvider.current].
const kPencilSharpener2026 = EventDefinition(
  id: 'pencil_sharpener_2026_05',
  name: 'Pencil Sharpener',
  start: DateTime(2026, 5, 3),
  end: DateTime(2026, 5, 16), // exclusive
  windowLabel: 'May 3 – 15',
  milestones: [
    EventMilestone(
      xp: 1000,
      cosmeticId: 'pencil_badge',
      kind: EventRewardKind.badge,
      title: '1000 XP · Pencil Badge',
      subtitle: 'Unlock and auto-equip your new pencil badge.',
      emoji: '✏️',
    ),
    EventMilestone(
      xp: 2000,
      cosmeticId: 'sharpener_profile_frame',
      kind: EventRewardKind.profileFrame,
      title: '2000 XP · Profile Frame',
      subtitle: 'Unlock the yellow + black sharpener-glow profile frame.',
      emoji: '🟨',
    ),
    EventMilestone(
      xp: 3000,
      cosmeticId: 'animated_sharpener_nameplate',
      kind: EventRewardKind.nameplate,
      title: '3000 XP · Animated Nameplate',
      subtitle: 'Unlock and auto-equip the animated sharpener nameplate.',
      emoji: '⚡',
    ),
  ],
);

/// Holiday event: "Cocoa Clash", Dec 1 – 25, 2026.
///
/// Milestone shape kept from Pencil Sharpener (1k / 2k / 3k XP): the window
/// is longer (25 days vs 13), so the top tier is easier to reach than it
/// was in May, but the shape is familiar and the weekend cap still throttles
/// farming. Rewards are holiday cosmetics (badge → profile frame → animated
/// nameplate).
const kCocoaClash2026 = EventDefinition(
  id: 'cocoa_clash_2026_12',
  name: 'Cocoa Clash',
  start: DateTime(2026, 12, 1),
  end: DateTime(2026, 12, 26), // exclusive — Dec 25 is the last full day
  windowLabel: 'Dec 1 – 25',
  milestones: [
    EventMilestone(
      xp: 1000,
      cosmeticId: 'cocoa_badge',
      kind: EventRewardKind.badge,
      title: '1000 XP · Cocoa Badge',
      subtitle: 'Unlock and auto-equip your new cocoa badge.',
      emoji: '☕',
    ),
    EventMilestone(
      xp: 2000,
      cosmeticId: 'cocoa_profile_frame',
      kind: EventRewardKind.profileFrame,
      title: '2000 XP · Cocoa Profile Frame',
      subtitle: 'Unlock the cocoa + marshmallow-glow profile frame.',
      emoji: '🖼️',
    ),
    EventMilestone(
      xp: 3000,
      cosmeticId: 'animated_cocoa_nameplate',
      kind: EventRewardKind.nameplate,
      title: '3000 XP · Animated Cocoa Nameplate',
      subtitle: 'Unlock and auto-equip the animated cocoa nameplate.',
      emoji: '✨',
    ),
  ],
);

/// Manages the current limited-time XP event ([kCocoaClash2026]).
///
/// Progress is based on XP earned from assignment completions recorded via
/// [recordAssignmentCompletion].
class EventProvider extends ChangeNotifier {
  /// The event currently being run. Swap this to ship the next event.
  static const EventDefinition current = kCocoaClash2026;

  /// Id of the current event (Firestore doc id + persistence-key namespace).
  static String get eventId => current.id;

  static DateTime get _eventStart => current.start;
  static DateTime get _eventEnd => current.end;

  /// Milestones (1-indexed): [0, ...milestone XP thresholds].
  /// Kept as a list for existing callers (`milestoneXp[3]` = top tier).
  static List<int> get milestoneXp =>
      [0, ...current.milestones.map((m) => m.xp)];

  /// Weekend double-XP bonus cap per day.
  static int get weekendBonusDailyCap => current.weekendBonusDailyCap;

  // ── Persistence keys (derived from the event id) ──────────────────────

  static String get _prefTotalXp => 'event_${eventId}_total_xp';
  static String get _prefClaimed => 'event_${eventId}_claimed_milestones';
  static String get _prefCountedIds =>
      'event_${eventId}_counted_assignment_ids';
  static String get _prefWeekendBonusByDay =>
      'event_${eventId}_weekend_bonus_by_day';

  // ── State ───────────────────────────────────────────────────────────────

  int _totalXp = 0;
  final Set<int> _claimedMilestones = {};
  final Set<String> _countedAssignmentIds = {};
  final Map<String, int> _weekendBonusByDay = {};
  String? _uid;

  // ── Getters ─────────────────────────────────────────────────────────────

  /// The definition of the event currently being run.
  EventDefinition get definition => current;

  String get eventName => current.name;

  String get windowLabel => current.windowLabel;

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

  Duration get timeUntilEnd {
    final now = DateTime.now();
    if (now.isAfter(_eventEnd)) return Duration.zero;
    return _eventEnd.difference(now);
  }

  int get milestoneCount => current.milestones.length;

  /// 1-indexed milestone definition, or null when out of range.
  EventMilestone? milestone(int milestone) {
    if (milestone < 1 || milestone > current.milestones.length) return null;
    return current.milestones[milestone - 1];
  }

  int get highestReachedMilestone {
    for (int m = current.milestones.length; m >= 1; m--) {
      if (_totalXp >= milestoneXp[m]) return m;
    }
    return 0;
  }

  /// Backward-compatible alias for older screen code.
  int get highestReachedTier => highestReachedMilestone;

  int get currentWorkingMilestone {
    final reached = highestReachedMilestone;
    return reached < milestoneCount ? reached + 1 : milestoneCount;
  }

  int get progressToCurrentMilestone {
    if (highestReachedMilestone >= milestoneCount) {
      return milestoneXp[milestoneCount];
    }
    return _totalXp;
  }

  int get currentMilestoneGoal => milestoneXp[currentWorkingMilestone];

  bool isMilestoneReached(int milestone) {
    if (milestone < 1 || milestone > milestoneCount) return false;
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

  // ── Local persistence ───────────────────────────────────────────────────

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
