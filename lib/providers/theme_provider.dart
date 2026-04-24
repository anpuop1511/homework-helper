import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

/// Represents an app color "Vibe" — a named theme variant.
enum AppVibe {
  systemDynamic,
  defaultPurple,
  midnight,
  sunset,
  forest,
  ocean,
  cyberpunk,
  sakura,
  springMint,
  cherryBlossom,
  skyBloom,
  daffodil,
  lavaPop,
  arcticPulse,
  neonForest,
  // ── Premium vibes (requires Helper+ or Helper Pass) ──────────────────────
  neonSunrise,
  deepOcean,
}

/// The set of vibes that require an active Helper+ or Helper Pass subscription.
const Set<AppVibe> kPremiumVibes = {
  AppVibe.neonSunrise,
  AppVibe.deepOcean,
};

extension AppVibeExtension on AppVibe {
  String get label {
    switch (this) {
      case AppVibe.systemDynamic:
        return 'Device Colors';
      case AppVibe.defaultPurple:
        return 'Default';
      case AppVibe.midnight:
        return 'Midnight';
      case AppVibe.sunset:
        return 'Sunset';
      case AppVibe.forest:
        return 'Forest';
      case AppVibe.ocean:
        return 'Ocean';
      case AppVibe.cyberpunk:
        return 'Cyberpunk';
      case AppVibe.sakura:
        return 'Sakura';
      case AppVibe.springMint:
        return 'Spring Mint';
      case AppVibe.cherryBlossom:
        return 'Cherry Blossom';
      case AppVibe.skyBloom:
        return 'Sky Bloom';
      case AppVibe.daffodil:
        return 'Daffodil';
      case AppVibe.lavaPop:
        return 'Lava Pop';
      case AppVibe.arcticPulse:
        return 'Arctic Pulse';
      case AppVibe.neonForest:
        return 'Neon Forest';
      case AppVibe.neonSunrise:
        return 'Neon Sunrise';
      case AppVibe.deepOcean:
        return 'Deep Ocean';
    }
  }

  String get emoji {
    switch (this) {
      case AppVibe.systemDynamic:
        return '📱';
      case AppVibe.defaultPurple:
        return '💜';
      case AppVibe.midnight:
        return '🌙';
      case AppVibe.sunset:
        return '🌅';
      case AppVibe.forest:
        return '🌿';
      case AppVibe.ocean:
        return '🌊';
      case AppVibe.cyberpunk:
        return '🤖';
      case AppVibe.sakura:
        return '🌸';
      case AppVibe.springMint:
        return '🌿';
      case AppVibe.cherryBlossom:
        return '🌸';
      case AppVibe.skyBloom:
        return '🩵';
      case AppVibe.daffodil:
        return '🌼';
      case AppVibe.lavaPop:
        return '🌋';
      case AppVibe.arcticPulse:
        return '🧊';
      case AppVibe.neonForest:
        return '🌲';
      case AppVibe.neonSunrise:
        return '🌄';
      case AppVibe.deepOcean:
        return '🌌';
    }
  }

  Color get seedColor {
    switch (this) {
      case AppVibe.systemDynamic:
        return Colors.blue;
      case AppVibe.defaultPurple:
        return const Color(0xFF6750A4);
      case AppVibe.midnight:
        return const Color(0xFF1A237E);
      case AppVibe.sunset:
        return const Color(0xFFE64A19);
      case AppVibe.forest:
        return const Color(0xFF2E7D32);
      case AppVibe.ocean:
        return const Color(0xFF006064);
      case AppVibe.cyberpunk:
        return const Color(0xFFFF0080); // neon pink
      case AppVibe.sakura:
        return const Color(0xFFFF8FAB); // sakura pink
      case AppVibe.springMint:
        return const Color(0xFF26A69A);
      case AppVibe.cherryBlossom:
        return const Color(0xFFE91E8C);
      case AppVibe.skyBloom:
        return const Color(0xFF0288D1);
      case AppVibe.daffodil:
        return const Color(0xFFF9A825);
      case AppVibe.lavaPop:
        return const Color(0xFFE53935);
      case AppVibe.arcticPulse:
        return const Color(0xFF00ACC1);
      case AppVibe.neonForest:
        return const Color(0xFF2E7D32);
      case AppVibe.neonSunrise:
        return const Color(0xFFFF6B00); // vivid orange-red
      case AppVibe.deepOcean:
        return const Color(0xFF003D8F); // deep navy blue
    }
  }
}

/// Manages the active [AppVibe] and notifies listeners on change.
/// Persists the chosen vibe locally via [SharedPreferences] and, when a
/// Firebase UID is available, syncs it to Cloud Firestore.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_vibe';

  AppVibe _vibe = AppVibe.systemDynamic;
  String? _uid;

  AppVibe get vibe => _vibe;

  ThemeProvider() {
    _loadVibe();
  }

  Future<void> _loadVibe() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIndex = prefs.getInt(_prefKey);
    if (storedIndex != null &&
        storedIndex >= 0 &&
        storedIndex < AppVibe.values.length) {
      _vibe = AppVibe.values[storedIndex];
      notifyListeners();
    }
  }

  /// Called when the user signs in or out so the vibe can be synced.
  Future<void> setUid(String? uid) async {
    _uid = uid;
    if (uid == null) return;
    // Load vibe from cloud; if it differs from local, prefer cloud.
    try {
      final data = await DatabaseService.instance.getUserData(uid);
      final cloudIndex = data?['vibe'] as int?;
      if (cloudIndex != null &&
          cloudIndex >= 0 &&
          cloudIndex < AppVibe.values.length) {
        final cloudVibe = AppVibe.values[cloudIndex];
        if (cloudVibe != _vibe) {
          _vibe = cloudVibe;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefKey, cloudVibe.index);
          notifyListeners();
        }
      }
    } catch (_) {
      // Firestore unavailable — keep local vibe.
    }
  }

  Future<void> setVibe(AppVibe vibe) async {
    if (_vibe == vibe) return;
    _vibe = vibe;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, vibe.index);
    if (_uid != null) {
      await DatabaseService.instance.saveVibe(_uid!, vibe);
    }
  }

  /// Reverts to the default vibe if the currently-set vibe requires a
  /// subscription that is no longer active.
  ///
  /// Called by [ChangeNotifierProxyProvider] whenever [EntitlementsProvider]
  /// changes.  The custom theme **configuration** is NOT deleted — it will
  /// be restored when the user resubscribes.
  Future<void> enforceEntitlements({required bool hasPlus}) async {
    // Helper+ has been retired; existing vibes stay available.
  }
}
