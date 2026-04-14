import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifies each bottom-navigation tab.
enum NavTab {
  home,
  focus,
  helper,
  social,
  classes,
  subjects,
}

extension NavTabExtension on NavTab {
  String get id => name; // e.g. 'home', 'focus', …

  String get label {
    switch (this) {
      case NavTab.home:
        return 'Home';
      case NavTab.focus:
        return 'Focus';
      case NavTab.helper:
        return 'Helper';
      case NavTab.social:
        return 'Social';
      case NavTab.classes:
        return 'Classes';
      case NavTab.subjects:
        return 'Subjects';
    }
  }

  IconData get icon {
    switch (this) {
      case NavTab.home:
        return Icons.home_outlined;
      case NavTab.focus:
        return Icons.timer_outlined;
      case NavTab.helper:
        return Icons.auto_awesome_outlined;
      case NavTab.social:
        return Icons.people_outline_rounded;
      case NavTab.classes:
        return Icons.school_outlined;
      case NavTab.subjects:
        return Icons.folder_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case NavTab.home:
        return Icons.home_rounded;
      case NavTab.focus:
        return Icons.timer_rounded;
      case NavTab.helper:
        return Icons.auto_awesome_rounded;
      case NavTab.social:
        return Icons.people_rounded;
      case NavTab.classes:
        return Icons.school_rounded;
      case NavTab.subjects:
        return Icons.folder_rounded;
    }
  }
}

/// Manages the user's bottom-navigation-bar customisation preferences.
///
/// Users can reorder and hide/show tabs.  The [NavTab.home] tab is always
/// visible and cannot be hidden.  At least one other tab must remain
/// visible as well.  Preferences are persisted locally via [SharedPreferences].
class NavBarProvider extends ChangeNotifier {
  static const _prefOrder = 'nav_tab_order';
  static const _prefHidden = 'nav_hidden_tabs';

  /// Tabs that are hidden by default (opt-in).
  static const _kDefaultHidden = {NavTab.classes, NavTab.subjects};

  /// Ordered list of all tabs (visible + hidden).
  List<NavTab> _tabOrder = List.of(NavTab.values);

  /// Set of tabs the user has chosen to hide.
  Set<NavTab> _hiddenTabs = Set.of(_kDefaultHidden);

  NavBarProvider() {
    _loadPrefs();
  }

  /// All tabs in user-configured order (both visible and hidden).
  List<NavTab> get tabOrder => List.unmodifiable(_tabOrder);

  /// Only the tabs that are currently visible, in order.
  List<NavTab> get visibleTabs =>
      _tabOrder.where((t) => !_hiddenTabs.contains(t)).toList();

  /// Whether [tab] is currently hidden.
  bool isHidden(NavTab tab) => _hiddenTabs.contains(tab);

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final orderRaw = prefs.getStringList(_prefOrder);
    final hiddenRaw = prefs.getStringList(_prefHidden);

    if (orderRaw == null || hiddenRaw == null) {
      // First launch — apply factory defaults (classes + subjects hidden).
      _hiddenTabs = Set.of(_kDefaultHidden);
      notifyListeners();
      return;
    }

    // Existing user: restore their stored configuration.
    final parsed = orderRaw
        .map((s) => NavTab.values.where((t) => t.id == s).firstOrNull)
        .whereType<NavTab>()
        .toList();
    final storedHidden = hiddenRaw
        .map((s) => NavTab.values.where((t) => t.id == s).firstOrNull)
        .whereType<NavTab>()
        .toSet();

    // Append any tabs added in newer app versions.
    // Opt-in tabs (_kDefaultHidden) start hidden; all others start visible.
    for (final tab in NavTab.values) {
      if (!parsed.contains(tab)) {
        parsed.add(tab);
        if (_kDefaultHidden.contains(tab)) {
          storedHidden.add(tab);
        }
      }
    }

    _tabOrder = parsed;
    _hiddenTabs = storedHidden;
    // Home is always visible.
    _hiddenTabs.remove(NavTab.home);
    _ensureOneVisible();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefOrder, _tabOrder.map((t) => t.id).toList());
    await prefs.setStringList(
        _prefHidden, _hiddenTabs.map((t) => t.id).toList());
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Reorders the tab at [oldIndex] to [newIndex] in [_tabOrder].
  void reorderTab(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) newIndex--;
    final tab = _tabOrder.removeAt(oldIndex);
    _tabOrder.insert(newIndex, tab);
    notifyListeners();
    _savePrefs().ignore();
  }

  /// Toggles the visibility of [tab].
  ///
  /// The [NavTab.home] tab can never be hidden.
  /// At least one non-home tab must remain visible.
  void toggleTab(NavTab tab, {required bool visible}) {
    // Home is always visible.
    if (tab == NavTab.home) return;
    if (!visible) {
      // Would hiding this tab leave zero visible tabs (excluding home)?
      final wouldBeVisible = _tabOrder
          .where((t) => t != tab && t != NavTab.home && !_hiddenTabs.contains(t))
          .toList();
      if (wouldBeVisible.isEmpty) return; // Refuse to hide the last non-home tab.
      _hiddenTabs.add(tab);
    } else {
      _hiddenTabs.remove(tab);
    }
    notifyListeners();
    _savePrefs().ignore();
  }

  /// Resets the tab order and visibility to the factory defaults.
  void resetToDefaults() {
    _tabOrder = List.of(NavTab.values);
    _hiddenTabs = Set.of(_kDefaultHidden);
    notifyListeners();
    _savePrefs().ignore();
  }

  void _ensureOneVisible() {
    // Home is always visible — remove it from the hidden set.
    _hiddenTabs.remove(NavTab.home);
    // Ensure at least one non-home tab is also visible.
    final nonHomeVisible = _tabOrder
        .where((t) => t != NavTab.home && !_hiddenTabs.contains(t))
        .toList();
    if (nonHomeVisible.isEmpty) {
      final firstNonHome =
          _tabOrder.where((t) => t != NavTab.home).firstOrNull;
      if (firstNonHome != null) _hiddenTabs.remove(firstNonHome);
    }
  }
}
