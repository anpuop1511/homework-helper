import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

/// Manages the user's gamification state: XP, level, streak, and Battle Pass.
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

  // Battle Pass prefs
  static const _prefBpCoins = 'bp_coins';
  static const _prefBpSeasonTier = 'bp_season_tier';
  static const _prefBpSeasonXp = 'bp_season_xp';
  static const _prefBpPassType = 'bp_pass_type';
  static const _prefBpUnlockedCosmetics = 'bp_unlocked_cosmetics';
  static const _prefBpActiveNameplate = 'bp_active_nameplate';
  static const _prefBpClaimedTiers = 'bp_claimed_tiers';
  static const _prefBpEquippedBadge = 'bp_equipped_badge';
  static const _prefBpEquippedNameColor = 'bp_equipped_name_color';

  /// XP required to advance from level N to N+1 = baseXp * N.
  static const int _baseXp = 100;

  int _xp = 0;
  int _level = 1;
  int _streak = 0;
  String _name = '';
  String _bio = '';
  DateTime? _lastActiveDate;

  // Battle Pass fields
  int _coins = 0;
  int _seasonTier = 1;
  int _seasonXp = 0;
  String _passType = 'free';
  List<String> _unlockedCosmetics = [];
  String _activeNameplate = '';
  List<int> _claimedTiers = [];
  String _equippedBadge = '';
  String _equippedNameColor = '';

  /// In-memory dev flag: when true the Season Shop shows all timed drops as
  /// available regardless of the real-time unlock date.  Not persisted.
  bool _shopTimeTravelEnabled = false;

  /// UID of the currently signed-in Firebase user, or null for guest mode.
  String? _uid;

  int get xp => _xp;
  int get level => _level;
  int get streak => _streak;
  String get name => _name;
  String get bio => _bio;

  // Battle Pass getters
  int get coins => _coins;
  int get seasonTier => _seasonTier;
  int get seasonXp => _seasonXp;
  String get passType => _passType;
  List<String> get unlockedCosmetics => List.unmodifiable(_unlockedCosmetics);
  String get activeNameplate => _activeNameplate;
  List<int> get claimedTiers => List.unmodifiable(_claimedTiers);
  String get equippedBadge => _equippedBadge;
  String get equippedNameColor => _equippedNameColor;

  /// Dev-only: when true the Season Shop shows all timed drops as available.
  bool get shopTimeTravelEnabled => _shopTimeTravelEnabled;

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
    _name = prefs.getString(_prefName) ?? '';
    final lastMs = prefs.getInt(_prefLastActive);
    if (lastMs != null) {
      _lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    // Battle Pass
    _coins = prefs.getInt(_prefBpCoins) ?? 0;
    _seasonTier = prefs.getInt(_prefBpSeasonTier) ?? 1;
    _seasonXp = prefs.getInt(_prefBpSeasonXp) ?? 0;
    _passType = prefs.getString(_prefBpPassType) ?? 'free';
    _unlockedCosmetics =
        prefs.getStringList(_prefBpUnlockedCosmetics) ?? [];
    _activeNameplate = prefs.getString(_prefBpActiveNameplate) ?? '';
    _claimedTiers =
        (prefs.getStringList(_prefBpClaimedTiers) ?? [])
            .map(int.parse)
            .toList();
    _equippedBadge = prefs.getString(_prefBpEquippedBadge) ?? '';
    _equippedNameColor = prefs.getString(_prefBpEquippedNameColor) ?? '';
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
    // Battle Pass
    await prefs.setInt(_prefBpCoins, _coins);
    await prefs.setInt(_prefBpSeasonTier, _seasonTier);
    await prefs.setInt(_prefBpSeasonXp, _seasonXp);
    await prefs.setString(_prefBpPassType, _passType);
    await prefs.setStringList(_prefBpUnlockedCosmetics, _unlockedCosmetics);
    await prefs.setString(_prefBpActiveNameplate, _activeNameplate);
    await prefs.setStringList(
        _prefBpClaimedTiers, _claimedTiers.map((t) => t.toString()).toList());
    await prefs.setString(_prefBpEquippedBadge, _equippedBadge);
    await prefs.setString(_prefBpEquippedNameColor, _equippedNameColor);
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
    final localName = prefs.getString(_prefName) ?? '';
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
    _name = (data['name'] as String?) ?? '';
    _bio = (data['bio'] as String?) ?? '';
    final lastMs = data['lastActiveDate'] as int?;
    if (lastMs != null) {
      _lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    // Battle Pass
    _coins = (data['bp_coins'] as int?) ?? _coins;
    _seasonTier = (data['bp_seasonTier'] as int?) ?? _seasonTier;
    _seasonXp = (data['bp_seasonXp'] as int?) ?? _seasonXp;
    _passType = (data['bp_passType'] as String?) ?? _passType;
    final rawCosmetics = data['bp_unlockedCosmetics'];
    if (rawCosmetics is List) {
      _unlockedCosmetics = rawCosmetics.cast<String>();
    }
    _activeNameplate =
        (data['bp_activeNameplate'] as String?) ?? _activeNameplate;
    final rawTiers = data['bp_claimedTiers'];
    if (rawTiers is List) {
      _claimedTiers = rawTiers.cast<int>();
    }
    _equippedBadge = (data['bp_equippedBadge'] as String?) ?? _equippedBadge;
    _equippedNameColor =
        (data['bp_equippedNameColor'] as String?) ?? _equippedNameColor;
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
      await DatabaseService.instance.saveBattlePassData(
        uid: _uid!,
        coins: _coins,
        seasonTier: _seasonTier,
        seasonXp: _seasonXp,
        passType: _passType,
        unlockedCosmetics: _unlockedCosmetics,
        activeNameplate: _activeNameplate,
        claimedTiers: _claimedTiers,
        equippedBadge: _equippedBadge,
        equippedNameColor: _equippedNameColor,
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

  /// Awards [amount] XP and handles level-ups; awards 50 coins per level-up.
  void awardXp(int amount) {
    assert(amount > 0, 'awardXp called with non-positive amount: $amount');
    if (amount <= 0) return;
    _xp += amount;
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level += 1;
      _coins += 50; // bonus coins for leveling up
    }
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    updateStudyWidget(streak: _streak, level: _level);
  }

  /// Awards [amount] coins to the user.
  void awardCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Deducts [amount] coins if the user has enough. Returns true on success.
  bool spendCoins(int amount) {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
    return true;
  }

  /// Sets the Battle Pass type ('free', 'plus', 'premium').
  void setPassType(String type) {
    _passType = type;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Adds [amount] season XP and advances tiers (every 100 season XP = 1 tier, max 50).
  /// Awards coins automatically from tier bonuses.
  void addSeasonXp(int amount) {
    if (amount <= 0) return;
    _seasonXp += amount;
    while (_seasonXp >= 100 && _seasonTier < 50) {
      _seasonXp -= 100;
      _seasonTier += 1;
      // Award tier-up bonus coins
      if (_seasonTier % 10 == 0) {
        _coins += 50; // bigger bonus every 10 tiers
      } else {
        _coins += 10;
      }
    }
    if (_seasonTier >= 50) {
      _seasonXp = 0;
    }
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Sets the active nameplate cosmetic.
  void setActiveNameplate(String nameplate) {
    _activeNameplate = nameplate;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Equips a nameplate (alias for [setActiveNameplate]).
  void equipNameplate(String id) => setActiveNameplate(id);

  /// Equips a badge cosmetic. Only owned items may be equipped.
  void equipBadge(String id) {
    _equippedBadge = id;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Equips a name color cosmetic. Only owned items may be equipped.
  void equipNameColor(String id) {
    _equippedNameColor = id;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Adds a cosmetic to the unlocked list.
  void unlockCosmetic(String cosmetic) {
    if (!_unlockedCosmetics.contains(cosmetic)) {
      _unlockedCosmetics = [..._unlockedCosmetics, cosmetic];
      notifyListeners();
      _saveLocal();
      _syncToCloud();
    }
  }

  /// Marks a Battle Pass tier reward as claimed.
  ///
  /// [side] should be 'free' or 'premium' to track each track independently.
  /// This allows claiming both the free and premium reward for the same tier.
  /// The key is stored as a cosmetic entry: 'claimed_free_5' or 'claimed_premium_10'.
  void claimTierReward(int tier, {String side = 'free'}) {
    final cosmeticKey = 'claimed_${side}_$tier';
    if (!_unlockedCosmetics.contains(cosmeticKey)) {
      _unlockedCosmetics = [..._unlockedCosmetics, cosmeticKey];
      notifyListeners();
      _saveLocal();
      _syncToCloud();
    }
  }

  /// Returns true if a specific tier+side reward has been claimed.
  bool isTierRewardClaimed(int tier, {String side = 'free'}) {
    final cosmeticKey = 'claimed_${side}_$tier';
    return _unlockedCosmetics.contains(cosmeticKey);
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

  // ── Developer / QA helpers (dev-only) ────────────────────────────────────

  /// Toggles the Season Shop time-travel bypass (dev-only, not persisted).
  void setShopTimeTravel(bool enabled) {
    _shopTimeTravelEnabled = enabled;
    notifyListeners();
  }

  /// Instantly advances the Battle Pass to Tier 50.
  void maxBattlePass() {
    _seasonTier = 50;
    _seasonXp = 0;
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Unlocks every known cosmetic so the equip flow can be fully tested.
  void unlockAllCosmetics() {
    const all = [
      // Season Shop badges
      'spring_petal_badge', 'study_streak_frame', 'night_owl_badge',
      // Season Shop nameplates
      'blue_sky', 'daffodil_yellow', 'aurora_purple', 'ocean_deep',
      // Season Shop name colors
      'rainbow_name_color', 'crimson_name',
      // Battle-pass nameplates
      'nameplate_Cherry Blossom', 'animated_golden_cherry_blossom',
      // Battle-pass badges (free track)
      'badge_spring_sprout', 'badge_blossom_brawler', 'badge_petal_collector',
      'badge_bloom_scholar', 'badge_blossom_warrior',
      // Battle-pass badges (premium track)
      'badge_sakura_storm', 'badge_petal_warrior', 'badge_spring_royale',
      'badge_sakura_legend', 'badge_grand_blossom',
    ];
    for (final id in all) {
      if (!_unlockedCosmetics.contains(id)) {
        _unlockedCosmetics = [..._unlockedCosmetics, id];
      }
    }
    notifyListeners();
    _saveLocal();
    _syncToCloud();
  }

  /// Wipes the account back to day-one state (keeps the user signed in).
  ///
  /// Used in the dev menu to test the new-user experience without signing out.
  Future<void> resetForTesting() async {
    _xp = 0;
    _level = 1;
    _streak = 0;
    _name = '';
    _bio = '';
    _lastActiveDate = null;
    _coins = 0;
    _seasonTier = 1;
    _seasonXp = 0;
    _passType = 'free';
    _unlockedCosmetics = [];
    _activeNameplate = '';
    _claimedTiers = [];
    _equippedBadge = '';
    _equippedNameColor = '';
    notifyListeners();
    await _saveLocal();
    await _syncToCloud();
  }

  /// Signs the user out by resetting all local state and clearing persisted
  /// preferences.  The UI is responsible for navigating back to [LoginScreen].
  Future<void> logout() async {
    _xp = 0;
    _level = 1;
    _streak = 0;
    _name = '';
    _lastActiveDate = null;
    // Reset Battle Pass fields
    _coins = 0;
    _seasonTier = 1;
    _seasonXp = 0;
    _passType = 'free';
    _unlockedCosmetics = [];
    _activeNameplate = '';
    _claimedTiers = [];
    _equippedBadge = '';
    _equippedNameColor = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefXp);
    await prefs.remove(_prefLevel);
    await prefs.remove(_prefStreak);
    await prefs.remove(_prefName);
    await prefs.remove(_prefLastActive);
    await prefs.remove(_prefBpCoins);
    await prefs.remove(_prefBpSeasonTier);
    await prefs.remove(_prefBpSeasonXp);
    await prefs.remove(_prefBpPassType);
    await prefs.remove(_prefBpUnlockedCosmetics);
    await prefs.remove(_prefBpActiveNameplate);
    await prefs.remove(_prefBpClaimedTiers);
    await prefs.remove(_prefBpEquippedBadge);
    await prefs.remove(_prefBpEquippedNameColor);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
