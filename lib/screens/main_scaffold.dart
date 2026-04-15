import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/nav_bar_provider.dart';
import '../providers/security_provider.dart';
import '../providers/social_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/assignments_provider.dart';
import '../widgets/nameplate_widget.dart';
import 'battle_pass_screen.dart';
import 'login_screen.dart';
import 'season_shop_screen.dart';
import 'home_screen.dart';
import 'timer_screen.dart';
import 'chat_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'subjects_screen.dart';
import 'classes_screen.dart';

/// Returns the single character to use as a profile avatar initial.
/// Skips any leading '@' symbol (e.g. '@anpu' → 'A').
String _avatarInitialFor(String displayName) {
  final name = displayName.startsWith('@') ? displayName.substring(1) : displayName;
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// Maps a [NavTab] to its corresponding screen widget.
Widget _screenForTab(NavTab tab) {
  switch (tab) {
    case NavTab.home:
      return const HomeScreen();
    case NavTab.focus:
      return const TimerScreen();
    case NavTab.helper:
      return const ChatScreen();
    case NavTab.social:
      return const SocialScreen();
    case NavTab.classes:
      return const ClassesScreen();
    case NavTab.subjects:
      return const SubjectsScreen();
  }
}

/// The root scaffold of the app with adaptive navigation.
///
/// On **mobile (Android/iOS/web, width < 600 px)**: shows a [NavigationBar]
/// at the bottom (thumb-friendly).
///
/// On **desktop / tablet (width ≥ 600 px)**: shows a [NavigationRail] on the
/// left side so the layout feels like a dashboard rather than a stretched phone.
///
/// Profile and Settings are accessible via the top-right [CircleAvatar]
/// User Hub button.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  /// Use a NavigationRail instead of a BottomNavigationBar on wide screens
  /// (desktop / tablet, width ≥ 600 logical pixels).
  /// On mobile web (narrow viewport) we still want the BottomNavigationBar,
  /// so we check only the screen width rather than `kIsWeb`.
  bool get _useRail => MediaQuery.of(context).size.width >= 600;

  void _openUserHub() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UserHubSheet(),
    );
  }

  Widget _userHubButton(ColorScheme colorScheme, UserProvider user, AuthProvider auth) {
    final displayName = _resolveDisplayName(auth, user);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openUserHub,
        borderRadius: BorderRadius.circular(20),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            _avatarInitialFor(displayName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves the best display name from auth state, falling back to UserProvider.
  static String _resolveDisplayName(AuthProvider auth, UserProvider user) {
    final username = auth.username;
    if (username != null && username.isNotEmpty) return '@$username';
    final displayName = auth.currentUser?.displayName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    if (user.name.isNotEmpty) return user.name;
    return auth.email?.split('@').first ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final social = context.watch<SocialProvider>();
    final navBar = context.watch<NavBarProvider>();
    final hasPendingRequests = social.hasPendingRequests;

    final visibleTabs = navBar.visibleTabs;
    // Clamp the index without calling setState during build; the displayed
    // index is safely bounded and _currentIndex self-corrects on next tap.
    final safeIndex = _currentIndex.clamp(0, visibleTabs.length - 1);

    // Build the list of screens matching visible tabs.
    final screens = visibleTabs.map(_screenForTab).toList();

    if (_useRail) {
      // ── Wide screen: NavigationRail layout ─────────────────────────
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: colorScheme.surfaceContainerLow,
              selectedIndex: safeIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.selected,
              minWidth: 72,
              selectedIconTheme: IconThemeData(size: 28, color: colorScheme.primary),
              unselectedIconTheme: IconThemeData(size: 24, color: colorScheme.onSurfaceVariant),
              destinations: visibleTabs.map((tab) {
                final isSocial = tab == NavTab.social;
                return NavigationRailDestination(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  icon: isSocial
                      ? Badge(
                          isLabelVisible: hasPendingRequests,
                          child: Icon(tab.icon),
                        )
                      : Icon(tab.icon),
                  selectedIcon: isSocial
                      ? Badge(
                          isLabelVisible: hasPendingRequests,
                          child: Icon(tab.selectedIcon),
                        )
                      : Icon(tab.selectedIcon),
                  label: Text(tab.label),
                );
              }).toList(),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _userHubButton(colorScheme, user, auth),
                  ),
                ),
              ),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: IndexedStack(
                index: safeIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: Floating Material 3 bottom bar layout ────────────────
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          // Floating User Hub button in top-right corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _userHubButton(colorScheme, user, auth),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          elevation: 8,
          shadowColor: Colors.black.withAlpha(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: colorScheme.outlineVariant.withAlpha(120),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 72,
            indicatorColor: colorScheme.secondaryContainer,
            selectedIconTheme:
                IconThemeData(color: colorScheme.onSecondaryContainer),
            unselectedIconTheme:
                IconThemeData(color: colorScheme.onSurfaceVariant),
            selectedIndex: safeIndex,
            labelBehavior: navBar.showLabels
                ? NavigationDestinationLabelBehavior.alwaysShow
                : NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: visibleTabs.map((tab) {
              final isSocial = tab == NavTab.social;
              return NavigationDestination(
                icon: isSocial
                    ? Badge(
                        isLabelVisible: hasPendingRequests,
                        child: Icon(tab.icon),
                      )
                    : Icon(tab.icon),
                selectedIcon: isSocial
                    ? Badge(
                        isLabelVisible: hasPendingRequests,
                        child: Icon(tab.selectedIcon),
                      )
                    : Icon(tab.selectedIcon),
                label: tab.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}



/// The "Command Center" mini-panel that slides up when the user taps the
/// profile avatar.  Provides quick access to identity, theme switching,
/// security status, Ghost Mode, and settings.
class _UserHubSheet extends StatelessWidget {
  const _UserHubSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final security = context.watch<SecurityProvider>();
    final chat = context.watch<ChatProvider>();
    final assignments = context.watch<AssignmentsProvider>();
    final displayName = _MainScaffoldState._resolveDisplayName(auth, user);
    final completedCount =
        assignments.assignments.where((a) => a.isCompleted).length;
    final rank = _rankLabel(user.level, completedCount);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(160), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colorScheme.primary.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(70),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Avatar + Name + Rank badge ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _avatarInitialFor(displayName),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name + rank
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.activeNameplate.isNotEmpty)
                          NameplateWidget(
                            username: displayName,
                            nameplateId: user.activeNameplate,
                            fontSize: 15,
                          )
                        else
                          Text(
                            displayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: nameColorValue(user.equippedNameColor),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rank,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lv.${user.level} · ${user.streak} 🔥',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Security status badge
                  Tooltip(
                    message: security.isAppLockEnabled
                        ? 'App Lock active'
                        : 'App Lock off',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: security.isAppLockEnabled
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        security.isAppLockEnabled
                            ? Icons.fingerprint_rounded
                            : Icons.lock_open_rounded,
                        size: 20,
                        color: security.isAppLockEnabled
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick-action divider ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Quick Actions',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Theme Quick-Switch ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ThemeQuickSwitch(
                currentVibe: theme.vibe,
                onVibeSelected: (v) =>
                    context.read<ThemeProvider>().setVibe(v),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
            const SizedBox(height: 12),

            // ── Ghost Mode toggle ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _GhostModeRow(
                isEnabled: !chat.isHistoryEnabled,
                onToggle: (v) =>
                    context.read<ChatProvider>().setHistoryEnabled(!v),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
            const SizedBox(height: 16),

            Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: colorScheme.outlineVariant.withAlpha(100)),

            // ── My Profile ───────────────────────────────────────────
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.person_rounded,
                  color: colorScheme.primary),
              title: Text('My Profile', style: textTheme.bodyLarge),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                );
              },
            ),

            // ── Battle Pass ───────────────────────────────────────────
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.workspace_premium_rounded,
                  color: colorScheme.tertiary),
              title: Text('Battle Pass 🌸', style: textTheme.bodyLarge),
              subtitle: Text(
                'Season 1: Spring Bloomin\'',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BattlePassScreen()),
                );
              },
            ),

            // ── Season Shop ───────────────────────────────────────────
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.storefront_rounded,
                  color: colorScheme.primary),
              title: Text('Season Shop 🛒', style: textTheme.bodyLarge),
              subtitle: Text(
                'Exclusive cosmetics for coins',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SeasonShopScreen()),
                );
              },
            ),

            // ── Sign In (guest only) ──────────────────────────────────
            if (!auth.isSignedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Sign In',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            // ── Full Settings ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text(
                    'Full Settings',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a rank label based on user level and completed assignment count.
  static String _rankLabel(int level, int completedCount) {
    if (completedCount >= 25 || level >= 8) return '🏆 Homework Hero';
    if (completedCount >= 10 || level >= 5) return '⚡ Power User';
    if (level >= 3) return '📚 Scholar';
    return '🌱 Study Buddy';
  }
}

// ── Theme Quick-Switch row ────────────────────────────────────────────────

class _ThemeQuickSwitch extends StatelessWidget {
  final AppVibe currentVibe;
  final ValueChanged<AppVibe> onVibeSelected;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ThemeQuickSwitch({
    required this.currentVibe,
    required this.onVibeSelected,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Vibe  ·  ${currentVibe.emoji} ${currentVibe.label}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: const [
              AppVibe.defaultPurple,
              AppVibe.midnight,
              AppVibe.sunset,
              AppVibe.ocean,
              AppVibe.sakura,
            ].map((vibe) {
              final isSelected = vibe == currentVibe;
              return GestureDetector(
                onTap: () => onVibeSelected(vibe),
                child: Tooltip(
                  message: '${vibe.emoji} ${vibe.label}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 36 : 30,
                    height: isSelected ? 36 : 30,
                    decoration: BoxDecoration(
                      color: vibe.seedColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.onSurface,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: vibe.seedColor.withAlpha(120),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Ghost Mode row ────────────────────────────────────────────────────────

class _GhostModeRow extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _GhostModeRow({
    required this.isEnabled,
    required this.onToggle,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? colorScheme.secondaryContainer.withAlpha(180)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        value: isEnabled,
        onChanged: onToggle,
        secondary: Text('👻', style: const TextStyle(fontSize: 22)),
        title: Text(
          'Ghost Mode',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          isEnabled ? 'Chat history is paused' : 'History recording on',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
