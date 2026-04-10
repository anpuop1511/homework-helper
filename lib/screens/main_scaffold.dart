import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'subjects_screen.dart';
import 'timer_screen.dart';
import 'chat_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// The root scaffold of the app with adaptive navigation.
///
/// On **mobile (Android/iOS, portrait)**: shows a [NavigationBar] at the
/// bottom (thumb-friendly).
///
/// On **web / desktop / tablet (landscape, width ≥ 600 px)**: shows a
/// [NavigationRail] on the left side so the layout feels like a dashboard
/// rather than a stretched phone.
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

  static const List<Widget> _screens = [
    HomeScreen(),
    SubjectsScreen(),
    TimerScreen(),
    ChatScreen(),
    SocialScreen(),
  ];

  /// Use a NavigationRail instead of a BottomNavigationBar on wide screens
  /// (web, desktop, or any screen wider than 600 logical pixels).
  bool get _useRail =>
      kIsWeb || MediaQuery.of(context).size.width >= 600;

  static const List<NavigationRailDestination> _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder_rounded),
      label: Text('Subjects'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer_rounded),
      label: Text('Timer'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.smart_toy_outlined),
      selectedIcon: Icon(Icons.smart_toy_rounded),
      label: Text('AI Chat'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: Text('Social'),
    ),
  ];

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
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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
    if (user.name.isNotEmpty && user.name != 'Student') return user.name;
    return user.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();

    if (_useRail) {
      // ── Wide screen: NavigationRail layout ─────────────────────────
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: _railDestinations,
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
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: BottomNavigationBar layout ───────────────────────────
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating User Hub button in top-right corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _userHubButton(colorScheme, user, auth),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Social',
          ),
        ],
      ),
    );
  }
}


/// Bottom sheet that serves as the User Hub.
/// Shows profile stats and quick links to Profile and Settings screens.
class _UserHubSheet extends StatelessWidget {
  const _UserHubSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final displayName = _MainScaffoldState._resolveDisplayName(auth, user);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar + Name
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(displayName, style: textTheme.titleLarge),
          Text(
            'Level ${user.level} Scholar · ${user.streak} 🔥 day streak',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: colorScheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.person_rounded, color: colorScheme.primary),
            title: Text('My Profile', style: textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading:
                Icon(Icons.settings_outlined, color: colorScheme.primary),
            title: Text('Settings', style: textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
