import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

/// Manages the user's gamification state: XP, level, and study streak.
///
/// When a Firebase UID is set (via [setUid]) the provider mirrors all changes
/// to Cloud Firestore and, on first cloud login, migrates any locally stored
/// data so nothing is lost.
class UserProvider extends ChangeNotifier {
  static const _prefXp = 'user_xp';
  static const _prefLevel = 'user_level';
  static const _prefStreak = 'user_streak';
  static const _prefLastActive = 'user_last_active';
  static const _prefName = 'user_name';
  static const _prefMigrated = 'cloud_migrated';

  /// XP required to advance from level N to N+1 = baseXp * N.
  static const int _baseXp = 100;

  int _xp = 0;
  int _level = 1;
  int _streak = 0;
  String _name = 'Student';
  String _bio = '';
  DateTime? _lastActiveDate;

  /// UID of the currently signed-in Firebase user, or null for guest mode.
  String? _uid;

  int get xp => _xp;
  int get level => _level;
  int get streak => _streak;
  String get name => _name;
  String get bio => _bio;

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
    _loadLocal();
  }

  // ── Local persistence ────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
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

  Future<void> _saveLocal() async {
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

  // ── Cloud (Firestore) sync ───────────────────────────────────────────────

  /// Called when the user signs in or out.
  ///
  /// On sign-in ([uid] != null) the provider first checks whether a migration
  /// is needed (local data → cloud), then loads the cloud data as the source
  /// of truth.
  Future<void> setUid(String? uid) async {
    _uid = uid;
    if (uid == null) {
      // Signed out — reload local state.
      await _loadLocal();
      return;
    }
    try {
      await _migrateIfNeeded(uid);
      await _loadFromCloud(uid);
    } catch (_) {
      // Firestore unavailable — continue with local data.
    }
  }

  Future<void> _migrateIfNeeded(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_prefMigrated) ?? false;
    if (alreadyMigrated) return;

    // Only migrate if there is meaningful local data (non-default values).
    final localXp = prefs.getInt(_prefXp) ?? 0;
    final localLevel = prefs.getInt(_prefLevel) ?? 1;
    final localStreak = prefs.getInt(_prefStreak) ?? 0;
    final localName = prefs.getString(_prefName) ?? 'Student';
    final hasLocalData = localXp > 0 || localLevel > 1 || localStreak > 1;
    if (!hasLocalData) {
      await prefs.setBool(_prefMigrated, true);
      return;
    }

    // Check whether the Firestore document already exists.
    final cloudData = await DatabaseService.instance.getUserData(uid);
    if (cloudData == null) {
      // Push local data to the cloud.
      final lastMs = prefs.getInt(_prefLastActive);
      await DatabaseService.instance.saveUserStats(
        uid: uid,
        xp: localXp,
        level: localLevel,
        streak: localStreak,
        name: localName,
        lastActiveDate: lastMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastMs)
            : DateTime.now(),
      );
    }
    await prefs.setBool(_prefMigrated, true);
  }

  Future<void> _loadFromCloud(String uid) async {
    final data = await DatabaseService.instance.getUserData(uid);
    if (data == null) return;
    _xp = (data['xp'] as int?) ?? 0;
    _level = (data['level'] as int?) ?? 1;
    _streak = (data['streak'] as int?) ?? 0;
    _name = (data['name'] as String?) ?? 'Student';
    _bio = (data['bio'] as String?) ?? '';
    final lastMs = data['lastActiveDate'] as int?;
    if (lastMs != null) {
      _lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    notifyListeners();
    updateStudyWidget(streak: _streak, level: _level);
  }

  Future<void> _syncToCloud() async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.saveUserStats(
        uid: _uid!,
        xp: _xp,
        level: _level,
        streak: _streak,
        name: _name,
        lastActiveDate: _lastActiveDate ?? DateTime.now(),
      );
    } catch (_) {
      // Firestore unavailable — local data already saved.
    }
  }

  // ── Streak logic ─────────────────────────────────────────────────────────

  void _updateStreak() {
    final today = _dateOnly(DateTime.now());
    if (_lastActiveDate == null) {
      _streak = 1;
      _lastActiveDate = today;
      return;
    }
    final last = _dateOnly(_lastActiveDate!);
    final diff = today.difference(last).inDays;
    if (diff == 0) {
      return;
    } else if (diff == 1) {
      _streak += 1;
    } else {
      _streak = 1;
    }
    _lastActiveDate = today;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Awards [amount] XP and handles level-ups.
  void awardXp(int amount) {
    assert(amount > 0, 'awardXp called with non-positive amount: $amount');
    if (amount <= 0) return;
    _xp += amount;
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level += 1;
    }
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    updateStudyWidget(streak: _streak, level: _level);
  }

  /// Records activity for the day (call when user opens the app or completes a task).
  void recordActivity() {
    _updateStreak();
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    updateStudyWidget(streak: _streak, level: _level);
  }

  Future<void> setName(String name) async {
    if (_name == name) return;
    _name = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefName, name);
    await _syncToCloud();
  }

  /// Updates the in-memory bio and notifies listeners.
  /// The caller is responsible for persisting the value to Firestore.
  void setBio(String bio) {
    if (_bio == bio) return;
    _bio = bio;
    notifyListeners();
  }

  /// Signs the user out by resetting all local state and clearing persisted
  /// preferences.  The UI is responsible for navigating back to [LoginScreen].
  Future<void> logout() async {
    _xp = 0;
    _level = 1;
    _streak = 0;
    _name = 'Student';
    _lastActiveDate = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefXp);
    await prefs.remove(_prefLevel);
    await prefs.remove(_prefStreak);
    await prefs.remove(_prefName);
    await prefs.remove(_prefLastActive);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
