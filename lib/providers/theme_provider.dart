import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents an app color "Vibe" — a named theme variant.
enum AppVibe {
  defaultPurple,
  midnight,
  sunset,
  forest,
  ocean,
}

extension AppVibeExtension on AppVibe {
  String get label {
    switch (this) {
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
    }
  }

  String get emoji {
    switch (this) {
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
    }
  }

  Color get seedColor {
    switch (this) {
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
    }
  }
}

/// Manages the active [AppVibe] and notifies listeners on change.
/// Persists the chosen vibe via [SharedPreferences].
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_vibe';

  AppVibe _vibe = AppVibe.defaultPurple;

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

  Future<void> setVibe(AppVibe vibe) async {
    if (_vibe == vibe) return;
    _vibe = vibe;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, vibe.index);
  }
}
