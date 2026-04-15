import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

/// The state the ladder event is currently in.
enum EventState { upcoming, active, ended }

/// Manages the "Complete Assignments Ladder" limited-time event running
/// 2026-04-20 through 2026-04-24 (inclusive, local time).
///
/// Progress is driven by a single [totalCompletedDuringEvent] counter that
/// increments once per unique assignment ID completed within the event window.
/// Tier advancement is automatic; claiming is optional and can be done any time
/// (even after the event ends) for any tier the user has reached.
class EventProvider extends ChangeNotifier {
  // ── Event constants ──────────────────────────────────────────────────────

  static const String eventId = 'ladder_2026_04_20';

  static final DateTime _eventStart = DateTime(2026, 4, 20);
  static final DateTime _eventEnd = DateTime(2026, 4, 25); // exclusive boundary

  /// Goals per tier (1-indexed; index 0 unused).
  static const List<int> tierGoals = [
    0, // index 0 – placeholder
    1, 1, 1, 1, 1, // T1–T5
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, // T6–T18
    3, // T19
    4, // T20
  ];

  /// Cumulative completions needed to *reach* tier N (i.e. have claimed/passed T1..T(N-1)).
  /// cumulativeGoals[N] = sum of tierGoals[1..N].
  static final List<int> cumulativeGoals = _buildCumulative();

  static List<int> _buildCumulative() {
    final out = List<int>.filled(21, 0);
    for (int i = 1; i <= 20; i++) {
      out[i] = out[i - 1] + tierGoals[i];
    }
    return out;
  }

  /// Total direct coin rewards available across all tiers (T2,T3,T4,T6-T10,T12,T14,T15,T17).
  static const int totalDirectCoins = 155;

  // ── Persistence keys ─────────────────────────────────────────────────────

  static const _prefTotal = 'event_ladder_total';
  static const _prefClaimed = 'event_ladder_claimed';
  static const _prefCountedIds = 'event_ladder_counted_ids';

  // ── State ────────────────────────────────────────────────────────────────

  int _total = 0;
  final Set<int> _claimedTiers = {};
  final Set<String> _countedIds = {};
  String? _uid;

  // ── Getters ──────────────────────────────────────────────────────────────

  int get totalCompletedDuringEvent => _total;
  Set<int> get claimedTiers => Set.unmodifiable(_claimedTiers);

  EventState get state {
    final now = DateTime.now();
    if (now.isBefore(_eventStart)) return EventState.upcoming;
    if (now.isBefore(_eventEnd)) return EventState.active;
    return EventState.ended;
  }

  /// Countdown duration until event starts (zero if already started).
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(_eventStart)) return Duration.zero;
    return _eventStart.difference(now);
  }

  /// The highest tier the user has fully reached (cumulativeGoals[tier] <= total).
  int get highestReachedTier {
    for (int t = 20; t >= 1; t--) {
      if (_total >= cumulativeGoals[t]) return t;
    }
    return 0;
  }

  /// The tier currently being worked on (1-20).
  int get currentWorkingTier {
    final reached = highestReachedTier;
    return (reached < 20) ? reached + 1 : 20;
  }

  /// Progress within [currentWorkingTier] (0..goal).
  int get progressInCurrentTier {
    if (highestReachedTier >= 20) return tierGoals[20];
    final t = currentWorkingTier;
    final cumPrev = cumulativeGoals[t - 1];
    return (_total - cumPrev).clamp(0, tierGoals[t]);
  }

  int get goalOfCurrentTier => tierGoals[currentWorkingTier];

  /// Returns true if the user has accumulated enough completions to pass tier [t].
  bool isTierReached(int t) => _total >= cumulativeGoals[t];

  /// Returns true if the user has claimed the reward for tier [t].
  bool isTierClaimed(int t) => _claimedTiers.contains(t);

  // ── Constructor / init ───────────────────────────────────────────────────

  EventProvider() {
    _loadLocal();
  }

  // ── UID / cloud sync ─────────────────────────────────────────────────────

  Future<void> setUid(String? uid) async {
    _uid = uid;
    if (uid == null) {
      await _loadLocal();
      return;
    }
    try {
      await _loadFromCloud(uid);
    } catch (_) {
      // Cloud unavailable – local data already loaded.
    }
  }

  Future<void> _loadFromCloud(String uid) async {
    final data = await DatabaseService.instance.getEventData(uid, eventId);
    if (data == null) return;
    final cloudTotal = (data['total'] as int?) ?? 0;
    final cloudClaimed = (data['claimed'] as List?)?.cast<int>() ?? [];
    final cloudCounted = (data['countedIds'] as List?)?.cast<String>() ?? [];
    // Use the higher value to avoid rolling back progress.
    if (cloudTotal > _total) {
      _total = cloudTotal;
    }
    _claimedTiers.addAll(cloudClaimed);
    _countedIds.addAll(cloudCounted);
    notifyListeners();
    // Persist merged cloud data locally.
    await _saveLocal();
  }

  Future<void> _syncToCloud() async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.saveEventData(
        uid: _uid!,
        eventId: eventId,
        total: _total,
        claimedTiers: _claimedTiers.toList(),
        countedIds: _countedIds.toList(),
      );
    } catch (_) {
      // Cloud write failed – local data is already saved.
    }
  }

  // ── Local persistence ─────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _total = prefs.getInt(_prefTotal) ?? 0;
    final claimedRaw = prefs.getStringList(_prefClaimed) ?? [];
    _claimedTiers
      ..clear()
      ..addAll(claimedRaw.map(int.parse));
    final countedRaw = prefs.getStringList(_prefCountedIds) ?? [];
    _countedIds
      ..clear()
      ..addAll(countedRaw);
    notifyListeners();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTotal, _total);
    await prefs.setStringList(
        _prefClaimed, _claimedTiers.map((t) => t.toString()).toList());
    await prefs.setStringList(_prefCountedIds, _countedIds.toList());
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by [AssignmentsProvider] when an assignment transitions to
  /// completed.  Increments the counter if:
  ///   1. The event is currently active (now within the event window).
  ///   2. The [assignmentId] has not already been counted.
  ///
  /// The "completed during event" rule counts any assignment that transitions
  /// to the completed state while the event window is open, regardless of when
  /// it was created.
  void recordCompletion(String assignmentId) {
    if (state != EventState.active) return;
    if (_countedIds.contains(assignmentId)) return;
    _countedIds.add(assignmentId);
    _total += 1;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Claims the reward for tier [t].  Returns false if the tier has not been
  /// reached or has already been claimed.  The caller is responsible for
  /// actually granting the reward via [UserProvider].
  bool claimTier(int t) {
    if (!isTierReached(t)) return false;
    if (isTierClaimed(t)) return false;
    _claimedTiers.add(t);
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    return true;
  }

  // ── Dev helpers ───────────────────────────────────────────────────────────

  /// Resets all event progress (dev/QA only).
  Future<void> resetForTesting() async {
    _total = 0;
    _claimedTiers.clear();
    _countedIds.clear();
    notifyListeners();
    await _saveLocal();
    await _syncToCloud();
  }
}
