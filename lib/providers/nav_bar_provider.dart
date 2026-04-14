import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifies each bottom-navigation tab.
enum NavTab {
  home,
  focus,
  helper,
  social,
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
    }
  }
}

/// Manages the user's bottom-navigation-bar customisation preferences.
///
/// Users can reorder and hide/show tabs.  At least one tab must remain
/// visible.  Preferences are persisted locally via [SharedPreferences].
class NavBarProvider extends ChangeNotifier {
  static const _prefOrder = 'nav_tab_order';
  static const _prefHidden = 'nav_hidden_tabs';

  /// Ordered list of all tabs (visible + hidden).
  List<NavTab> _tabOrder = List.of(NavTab.values);

  /// Set of tabs the user has chosen to hide.
  Set<NavTab> _hiddenTabs = {};

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
    if (orderRaw != null) {
      final parsed = orderRaw
          .map((s) => NavTab.values.where((t) => t.id == s).firstOrNull)
          .whereType<NavTab>()
          .toList();
      // Append any new tabs that weren't stored (e.g. added in a later version).
      for (final tab in NavTab.values) {
        if (!parsed.contains(tab)) parsed.add(tab);
      }
      _tabOrder = parsed;
    }
    final hiddenRaw = prefs.getStringList(_prefHidden) ?? [];
    _hiddenTabs = hiddenRaw
        .map((s) => NavTab.values.where((t) => t.id == s).firstOrNull)
        .whereType<NavTab>()
        .toSet();
    // Ensure at least one tab is visible.
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

  /// Toggles the visibility of [tab].  At least one tab must remain visible.
  void toggleTab(NavTab tab, {required bool visible}) {
    if (!visible) {
      // Would hiding this tab leave zero visible tabs?
      final wouldBeVisible = _tabOrder
          .where((t) => t != tab && !_hiddenTabs.contains(t))
          .toList();
      if (wouldBeVisible.isEmpty) return; // Refuse to hide the last tab.
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
    _hiddenTabs = {};
    notifyListeners();
    _savePrefs().ignore();
  }

  void _ensureOneVisible() {
    final visible = _tabOrder.where((t) => !_hiddenTabs.contains(t)).toList();
    if (visible.isEmpty && _tabOrder.isNotEmpty) {
      _hiddenTabs.remove(_tabOrder.first);
    }
  }
}
