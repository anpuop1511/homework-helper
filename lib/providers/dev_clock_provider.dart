import 'package:flutter/foundation.dart';

/// Developer-only in-memory clock override for QA / time-travel testing.
///
/// When [isOverrideActive] is true, [nowUtc] returns [override] instead of the
/// real wall clock.  The override is **not** persisted — it resets whenever the
/// app is restarted.
class DevClockProvider extends ChangeNotifier {
  DateTime? _override;

  /// The frozen UTC instant, or null when the real clock is used.
  DateTime? get override => _override;

  /// True when a clock override is currently active.
  bool get isOverrideActive => _override != null;

  /// Returns the effective UTC "now": the frozen override if active, otherwise
  /// the real wall clock.
  DateTime nowUtc() => (_override ?? DateTime.now()).toUtc();

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
}
