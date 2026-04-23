import 'package:flutter/foundation.dart';
import '../config/season_live_ops.dart';

/// Developer-only in-memory clock override for QA / time-travel testing.
///
/// When [isOverrideActive] is true, [nowUtc] returns [override] instead of the
/// real wall clock.  The override is **not** persisted — it resets whenever the
/// app is restarted.
///
/// [forceSeason2] is the highest-priority override: when true, [nowUtc]
/// always returns the Season 2 start timestamp regardless of any date override,
/// making it easy to test Season 2 Battle Pass / shop behaviour instantly.
class DevClockProvider extends ChangeNotifier {
  DateTime? _override;
  bool _forceSeason2 = false;

  /// The frozen UTC instant, or null when the real clock is used.
  DateTime? get override => _override;

  /// True when a clock override is currently active.
  bool get isOverrideActive => _override != null;

  /// When true, [nowUtc] returns the Season 2 start time, overriding both the
  /// real clock and any manual date override.
  bool get forceSeason2 => _forceSeason2;

  /// Returns the effective UTC "now":
  /// 1. [kSeason2.startsAtUtc] when [forceSeason2] is true (highest priority).
  /// 2. The frozen [override] when one is active.
  /// 3. The real wall clock otherwise.
  DateTime nowUtc() {
    if (_forceSeason2) return kSeason2.startsAtUtc;
    return (_override ?? DateTime.now()).toUtc();
  }

  /// Freeze the clock to [value].  Stored as UTC internally.
  void setOverride(DateTime value) {
    _override = value.toUtc();
    notifyListeners();
  }

  /// Return to the real wall clock.
  void clearOverride() {
    _override = null;
    notifyListeners();
  }

  /// Force the effective time to Season 2 start (highest-priority debug flag).
  void setForceSeason2(bool value) {
    _forceSeason2 = value;
    notifyListeners();
  }
}
