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
}

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
}
