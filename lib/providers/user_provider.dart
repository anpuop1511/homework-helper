import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's gamification state: XP, level, and study streak.
/// All data is persisted via [SharedPreferences].
class UserProvider extends ChangeNotifier {
  static const _prefXp = 'user_xp';
  static const _prefLevel = 'user_level';
  static const _prefStreak = 'user_streak';
  static const _prefLastActive = 'user_last_active';
  static const _prefName = 'user_name';

  /// XP required to advance from level N to N+1 = baseXp * N.
  static const int _baseXp = 100;

  int _xp = 0;
  int _level = 1;
  int _streak = 0;
  String _name = 'Student';
  DateTime? _lastActiveDate;

  int get xp => _xp;
  int get level => _level;
  int get streak => _streak;
  String get name => _name;

  /// XP needed to reach the next level from the current one.
  int get xpForNextLevel => _baseXp * _level;

  /// Total XP earned across all levels (historical).
  int get totalXp {
    // Sum of XP for levels 1..(level-1) = _baseXp * (level-1)*level / 2
    final previousLevelsXp = _baseXp * (_level - 1) * _level ~/ 2;
    return previousLevelsXp + _xp;
  }

  /// Fraction of progress within the current level (0.0 – 1.0).
  double get levelProgress =>
      (xpForNextLevel > 0) ? (_xp / xpForNextLevel).clamp(0.0, 1.0) : 1.0;

  UserProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt(_prefXp) ?? 0;
    _level = prefs.getInt(_prefLevel) ?? 1;
    _streak = prefs.getInt(_prefStreak) ?? 0;
    _name = prefs.getString(_prefName) ?? 'Student';
    final lastMs = prefs.getInt(_prefLastActive);
    if (lastMs != null) {
      _lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _updateStreak();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefXp, _xp);
    await prefs.setInt(_prefLevel, _level);
    await prefs.setInt(_prefStreak, _streak);
    await prefs.setString(_prefName, _name);
    if (_lastActiveDate != null) {
      await prefs.setInt(
          _prefLastActive, _lastActiveDate!.millisecondsSinceEpoch);
    }
  }

  /// Updates the streak based on the last active date.
  void _updateStreak() {
    final today = _dateOnly(DateTime.now());
    if (_lastActiveDate == null) {
      // First use
      _streak = 1;
      _lastActiveDate = today;
      return;
    }
    final last = _dateOnly(_lastActiveDate!);
    final diff = today.difference(last).inDays;
    if (diff == 0) {
      // Already counted today
      return;
    } else if (diff == 1) {
      // Consecutive day
      _streak += 1;
    } else {
      // Streak broken
      _streak = 1;
    }
    _lastActiveDate = today;
  }

  /// Awards [amount] XP and handles level-ups.
  void awardXp(int amount) {
    assert(amount > 0, 'awardXp called with non-positive amount: $amount');
    if (amount <= 0) return;
    _xp += amount;
    // Level up while XP exceeds threshold
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level += 1;
    }
    notifyListeners();
    _save();
  }

  /// Records activity for the day (call when user opens the app or completes a task).
  void recordActivity() {
    _updateStreak();
    notifyListeners();
    _save();
  }

  Future<void> setName(String name) async {
    if (_name == name) return;
    _name = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefName, name);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
