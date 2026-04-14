import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment.dart';

/// Manages custom display names for the built-in subject categories.
///
/// Users can rename any default subject (e.g. rename "Science" → "Bio").
/// Custom names are persisted locally via [SharedPreferences] and are used
/// everywhere subjects are displayed or selected.
class SubjectsProvider extends ChangeNotifier {
  static const _prefPrefix = 'subject_custom_';

  /// Maps canonical subject name → custom display name.
  final Map<String, String> _customNames = {};

  SubjectsProvider() {
    _loadPrefs();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final subject in Subject.allSubjects) {
      if (subject == Subject.all) continue;
      final custom = prefs.getString('$_prefPrefix${subject}');
      if (custom != null && custom.isNotEmpty) {
        _customNames[subject] = custom;
      }
    }
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final subject in Subject.allSubjects) {
      if (subject == Subject.all) continue;
      final custom = _customNames[subject];
      if (custom != null) {
        await prefs.setString('$_prefPrefix${subject}', custom);
      } else {
        await prefs.remove('$_prefPrefix${subject}');
      }
    }
  }

  // ── Accessors ────────────────────────────────────────────────────────────

  /// Returns the custom display name for [canonical], or [canonical] itself
  /// if no custom name has been set.
  String displayName(String canonical) =>
      _customNames[canonical] ?? canonical;

  /// Returns the display names for all subjects except 'All',
  /// mapped canonical → display.
  Map<String, String> get allDisplayNames {
    final result = <String, String>{};
    for (final s in Subject.allSubjects) {
      if (s == Subject.all) continue;
      result[s] = displayName(s);
    }
    return result;
  }

  /// Whether a custom name is set for [canonical].
  bool hasCustomName(String canonical) => _customNames.containsKey(canonical);

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Sets a custom display name for [canonical].
  /// Pass an empty string to clear the custom name and revert to default.
  void setCustomName(String canonical, String customName) {
    final trimmed = customName.trim();
    if (trimmed.isEmpty || trimmed == canonical) {
      _customNames.remove(canonical);
    } else {
      _customNames[canonical] = trimmed;
    }
    notifyListeners();
    _savePrefs().ignore();
  }

  /// Clears all custom names, reverting every subject to its default label.
  void resetAll() {
    _customNames.clear();
    notifyListeners();
    _savePrefs().ignore();
  }
}
