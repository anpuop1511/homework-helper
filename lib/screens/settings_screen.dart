import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/security_provider.dart';
import '../providers/social_provider.dart';
import '../providers/theme_provider.dart';
import 'username_screen.dart';

// ── Settings landing page ─────────────────────────────────────────────────

/// Settings screen – Android-style landing page.
///
/// Displays a search bar and a vertical list of large rounded category tiles:
///   - Account
///   - AI & Models
///   - Appearance
///   - Notifications
///   - Privacy & Security
///   - About
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_CategoryData> _categories = [
    _CategoryData(
      icon: Icons.person_rounded,
      color: Color(0xFF6750A4),
      title: 'Account',
      subtitle: 'Username, password, sign out',
    ),
    _CategoryData(
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF0069C0),
      title: 'AI & Models',
      subtitle: 'Model selector, Bring Your Own Key',
    ),
    _CategoryData(
      icon: Icons.palette_rounded,
      color: Color(0xFF2E7D32),
      title: 'Appearance',
      subtitle: 'Color theme, vibe palette',
    ),
    _CategoryData(
      icon: Icons.notifications_rounded,
      color: Color(0xFFE64A19),
      title: 'Notifications',
      subtitle: 'Timer alerts, deadline reminders',
    ),
    _CategoryData(
      icon: Icons.shield_rounded,
      color: Color(0xFF37474F),
      title: 'Privacy & Security',
      subtitle: 'App lock, biometrics, data export',
    ),
    _CategoryData(
      icon: Icons.info_outline_rounded,
      color: Color(0xFF4E6B3A),
      title: 'About',
      subtitle: 'Version, device info',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategory(_CategoryData cat, BuildContext context) {
    Widget page;
    switch (cat.title) {
      case 'Account':
        page = const _AccountSettingsPage();
        break;
      case 'AI & Models':
        page = const _AiModelsSettingsPage();
        break;
      case 'Appearance':
        page = const _AppearanceSettingsPage();
        break;
      case 'Notifications':
        page = const _NotificationsSettingsPage();
        break;
      case 'Privacy & Security':
        page = const _PrivacySecuritySettingsPage();
        break;
      case 'About':
        page = const _AboutSettingsPage();
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filtered = _query.isEmpty
        ? _categories
        : _categories
            .where((c) =>
                c.title.toLowerCase().contains(_query.toLowerCase()) ||
                c.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search settings',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            // ── Category tiles ────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final cat = filtered[i];
                  return _SettingsCategoryTile(
                    data: cat,
                    colorScheme: colorScheme,
                    onTap: () => _openCategory(cat, context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Immutable descriptor for a settings category.
class _CategoryData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _CategoryData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

/// Large rounded tile matching Android Settings style.
class _SettingsCategoryTile extends StatelessWidget {
  final _CategoryData data;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SettingsCategoryTile({
    required this.data,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Circular icon avatar with tinted background
              CircleAvatar(
                radius: 24,
                backgroundColor: data.color.withAlpha(30),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category detail pages ─────────────────────────────────────────────────

/// Base scaffold used by all category detail pages.
class _CategoryPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CategoryPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface),
        ),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: children,
        ),
      ),
    );
  }
}

// ── Account ───────────────────────────────────────────────────────────────

class _AccountSettingsPage extends StatelessWidget {
  const _AccountSettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return _CategoryPage(
      title: 'Account',
      children: [
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              _SecurityTile(
                icon: Icons.alternate_email_rounded,
                title: auth.username != null && auth.username!.isNotEmpty
                    ? 'Change Username  (@${auth.username})'
                    : 'Set your @username',
                subtitle: auth.username != null && auth.username!.isNotEmpty
                    ? 'Update your unique @handle.'
                    : 'Pick a unique handle so friends can find you.',
                colorScheme: colorScheme,
                onTap: auth.isSignedIn
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const UsernameScreen(allowSkip: true),
                          ),
                        )
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              _SecurityTile(
                icon: Icons.lock_reset_rounded,
                title: 'Change Password',
                subtitle: 'Send a password-reset email.',
                colorScheme: colorScheme,
                onTap: auth.isSignedIn && auth.email != null
                    ? () => _sendPasswordReset(context, auth.email!)
                    : null,
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              _SecurityTile(
                icon: Icons.verified_user_rounded,
                title: 'Email Verification',
                subtitle: auth.isEmailVerified
                    ? 'Your email is verified \u2705'
                    : 'Send a verification email.',
                colorScheme: colorScheme,
                onTap: auth.isSignedIn && !auth.isEmailVerified
                    ? () => _sendVerification(context)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (auth.isSignedIn)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Sign Out',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reset email. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendVerification(BuildContext context) async {
    try {
      await context.read<AuthProvider>().sendEmailVerification();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send verification email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── AI & Models ───────────────────────────────────────────────────────────

class _AiModelsSettingsPage extends StatelessWidget {
  const _AiModelsSettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chat = context.watch<ChatProvider>();
    final security = context.watch<SecurityProvider>();
    return _CategoryPage(
      title: 'AI & Models',
      children: [
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.psychology_rounded,
                          color: colorScheme.onPrimaryContainer, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Model',
                              style: textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Choose the Gemini model to use.',
                              style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    DropdownButton<AiModel>(
                      value: chat.selectedModel,
                      underline: const SizedBox.shrink(),
                      items: AiModel.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.label, style: textTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (m) {
                        if (m != null) {
                          context.read<ChatProvider>().setModel(m);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // BYOK key input -- only visible when Custom is selected
              if (chat.selectedModel == AiModel.custom) ...[
                Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withAlpha(100)),
                _ByokKeyField(colorScheme: colorScheme),
              ],
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              // AI Features toggle
              SwitchListTile(
                value: security.isAiEnabled,
                onChanged: (v) =>
                    context.read<SecurityProvider>().setAiEnabled(v),
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: security.isAiEnabled
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: security.isAiEnabled
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  'AI Features',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  security.isAiEnabled
                      ? 'AI Study Buddy is active.'
                      : 'AI features have been revoked.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              // Ghost Mode
              SwitchListTile(
                value: !chat.isHistoryEnabled,
                onChanged: (v) =>
                    context.read<ChatProvider>().setHistoryEnabled(!v),
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: !chat.isHistoryEnabled
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('👻', style: TextStyle(fontSize: 20)),
                  ),
                ),
                title: Text(
                  'Ghost Mode',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  !chat.isHistoryEnabled
                      ? 'New chats are not saved to history.'
                      : 'Chat history is being recorded.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              // Clear Chat History
              _SecurityTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear Chat History',
                subtitle: 'Erase all AI Study Buddy messages.',
                colorScheme: colorScheme,
                onTap: () => _confirmClearChat(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Chat History?'),
        content: const Text(
            'This will erase all AI Study Buddy messages and start a fresh session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ChatProvider>().clearChat();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chat history cleared.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }
}

// ── Appearance ────────────────────────────────────────────────────────────

class _AppearanceSettingsPage extends StatelessWidget {
  const _AppearanceSettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final socialProvider = context.watch<SocialProvider>();
    return _CategoryPage(
      title: 'Appearance',
      children: [
        Text(
          'Choose a color palette that matches your mood.',
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: AppVibe.values.map((vibe) {
              final isSelected = themeProvider.vibe == vibe;
              final vibeScheme = ColorScheme.fromSeed(
                seedColor: vibe.seedColor,
                brightness: Theme.of(context).brightness,
              );
              return _VibeRow(
                vibe: vibe,
                vibeScheme: vibeScheme,
                isSelected: isSelected,
                onTap: () => context.read<ThemeProvider>().setVibe(vibe),
                showDivider: vibe != AppVibe.values.last,
                colorScheme: colorScheme,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.visibility_rounded,
                      color: colorScheme.onPrimaryContainer, size: 20),
                ),
                title: Text(
                  'Profile Visibility',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _profileVisibilityLabel(socialProvider.profileVisibility),
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: DropdownButton<ProfileVisibility>(
                  value: socialProvider.profileVisibility,
                  underline: const SizedBox.shrink(),
                  items: ProfileVisibility.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(_profileVisibilityLabel(v),
                          style: textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      context.read<SocialProvider>().setProfileVisibility(v);
                    }
                  },
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_rounded,
                      color: colorScheme.onSecondaryContainer, size: 20),
                ),
                title: Text(
                  'Who Can Add Me',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _friendRequestsLabel(socialProvider.friendRequestsPrivacy),
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: DropdownButton<FriendRequestsPrivacy>(
                  value: socialProvider.friendRequestsPrivacy,
                  underline: const SizedBox.shrink(),
                  items: FriendRequestsPrivacy.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(_friendRequestsLabel(v),
                          style: textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      context
                          .read<SocialProvider>()
                          .setFriendRequestsPrivacy(v);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _profileVisibilityLabel(ProfileVisibility v) {
    switch (v) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.friendsOnly:
        return 'Friends Only';
      case ProfileVisibility.private:
        return 'Private';
    }
  }

  String _friendRequestsLabel(FriendRequestsPrivacy v) {
    switch (v) {
      case FriendRequestsPrivacy.everyone:
        return 'Everyone';
      case FriendRequestsPrivacy.nobody:
        return 'Nobody';
    }
  }
}

// ── Notifications ─────────────────────────────────────────────────────────

class _NotificationsSettingsPage extends StatelessWidget {
  const _NotificationsSettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _CategoryPage(
      title: 'Notifications',
      children: [
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.timer_rounded,
                      color: colorScheme.onPrimaryContainer, size: 20),
                ),
                title: Text(
                  'Focus Timer Alerts',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Notify when a Pomodoro session ends.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: Switch(
                  value: true,
                  onChanged: (_) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Notification settings coming soon.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_rounded,
                      color: colorScheme.onSecondaryContainer, size: 20),
                ),
                title: Text(
                  'Deadline Reminders',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Get reminders before assignments are due.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: Switch(
                  value: true,
                  onChanged: (_) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Notification settings coming soon.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Privacy & Security ────────────────────────────────────────────────────

class _PrivacySecuritySettingsPage extends StatelessWidget {
  const _PrivacySecuritySettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final socialProvider = context.watch<SocialProvider>();
    return _CategoryPage(
      title: 'Privacy & Security',
      children: [
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              SwitchListTile(
                value: socialProvider.showStudyActivity,
                onChanged: (v) =>
                    context.read<SocialProvider>().setShowStudyActivity(v),
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.people_rounded,
                      color: colorScheme.onSecondaryContainer, size: 20),
                ),
                title: Text(
                  'Show Study Activity to Friends',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Let friends see when you are in a focus session.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              _SecurityTile(
                icon: Icons.file_download_rounded,
                title: 'Export My Data',
                subtitle: 'Download a copy of your data.',
                colorScheme: colorScheme,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Data export coming soon.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _BiometricsSection(colorScheme: colorScheme),
      ],
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────

class _AboutSettingsPage extends StatelessWidget {
  const _AboutSettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _CategoryPage(
      title: 'About',
      children: [
        _SquircleCard(
          colorScheme: colorScheme,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  'Homework Helper',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Version 2.5.0'),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(100)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  'Device',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_deviceLabel()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _deviceLabel() {
    if (kIsWeb) return 'Web Browser';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iPhone / iPad';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

/// Text field widget for entering a custom BYOK API key.
class _ByokKeyField extends StatefulWidget {
  final ColorScheme colorScheme;
  const _ByokKeyField({required this.colorScheme});

  @override
  State<_ByokKeyField> createState() => _ByokKeyFieldState();
}

class _ByokKeyFieldState extends State<_ByokKeyField> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final key = context.read<ChatProvider>().customApiKey;
    _controller = TextEditingController(text: key);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.vpn_key_rounded,
                    color: colorScheme.onTertiaryContainer, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Gemini API Key',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('Paste your key from Google AI Studio.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'AIza...',
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: colorScheme.outlineVariant),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.check_circle_rounded, size: 20),
                    color: colorScheme.primary,
                    tooltip: 'Save key',
                    onPressed: () {
                      context
                          .read<ChatProvider>()
                          .setCustomApiKey(_controller.text);
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('API key saved.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Squircle-style card with rounded corners and subtle border.
class _SquircleCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;

  const _SquircleCard({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _VibeRow extends StatelessWidget {
  final AppVibe vibe;
  final ColorScheme vibeScheme;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;
  final ColorScheme colorScheme;

  const _VibeRow({
    required this.vibe,
    required this.vibeScheme,
    required this.isSelected,
    required this.onTap,
    required this.showDivider,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    _Dot(color: vibeScheme.primary),
                    const SizedBox(width: 4),
                    _Dot(color: vibeScheme.secondary),
                    const SizedBox(width: 4),
                    _Dot(color: vibeScheme.tertiary),
                  ],
                ),
                const SizedBox(width: 12),
                Text(vibe.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vibe.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: colorScheme.outlineVariant.withAlpha(100)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right,
              color: colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

/// Biometrics & Passkey section -- stateful because it triggers async flows.
class _BiometricsSection extends StatefulWidget {
  final ColorScheme colorScheme;
  const _BiometricsSection({required this.colorScheme});

  @override
  State<_BiometricsSection> createState() => _BiometricsSectionState();
}

class _BiometricsSectionState extends State<_BiometricsSection> {
  bool _setupLoading = false;
  bool _deleteLoading = false;

  ColorScheme get cs => widget.colorScheme;

  Future<void> _setupPasskey(SecurityProvider security) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Your Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your password to securely link your biometric to your account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      passwordController.dispose();
      return;
    }

    final password = passwordController.text;
    passwordController.dispose();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password cannot be empty.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
      return;
    }

    setState(() => _setupLoading = true);

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.verifyCurrentPassword(password);
    } catch (_) {
      if (!mounted) return;
      setState(() => _setupLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Incorrect password. Passkey setup cancelled.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
      return;
    }

    final ok = await security.authenticate(
        reason: 'Register your biometric as a Passkey');
    if (!mounted) return;
    setState(() => _setupLoading = false);
    if (ok) {
      final email = authProvider.currentUserEmail ?? '';
      await security.storePasskeyCredentials(email, password);
      await security.setPasskeySet(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Passkey set up successfully! 🔑'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.primaryContainer,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verification failed.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _deletePasskey(SecurityProvider security) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Delete Passkey?'),
        content: const Text(
            'This will remove your saved Passkey. You can set it up again at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleteLoading = true);
    await security.setPasskeySet(false);
    if (!mounted) return;
    setState(() => _deleteLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Passkey deleted.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surfaceContainerHighest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    return _SquircleCard(
      colorScheme: cs,
      child: Column(
        children: [
          // App Lock toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lock_rounded,
                  color: cs.onPrimaryContainer, size: 20),
            ),
            title: Text(
              'App Lock',
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Require biometrics once when the app is launched.',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            value: security.isAppLockEnabled,
            onChanged: (v) => security.setAppLock(v),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(100)),
          // Biometric for NFC toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.nfc_rounded,
                  color: cs.onSecondaryContainer, size: 20),
            ),
            title: Text(
              'Biometric for NFC Bump',
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Verify your identity before starting a Bump.',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            value: security.isBioNfcEnabled,
            onChanged: (v) => security.setBioNfc(v),
          ),
          Divider(height: 1, color: cs.outlineVariant.withAlpha(100)),
          // Passkey setup / delete
          if (!security.isPasskeySet)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fingerprint_rounded,
                    color: cs.onTertiaryContainer, size: 20),
              ),
              title: Text(
                'Set up Passkey',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Register your biometric as a secure Passkey.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: _setupLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant),
              onTap:
                  _setupLoading ? null : () => _setupPasskey(security),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fingerprint_rounded,
                    color: cs.onTertiaryContainer, size: 20),
              ),
              title: Text(
                'Passkey Active \u2705',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Your biometric Passkey is registered.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            Divider(
                height: 1,
                color: cs.outlineVariant.withAlpha(100)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_rounded,
                    color: cs.onErrorContainer, size: 20),
              ),
              title: Text(
                'Delete Passkey',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.error),
              ),
              subtitle: Text(
                'Remove your saved biometric Passkey.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: _deleteLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant),
              onTap: _deleteLoading
                  ? null
                  : () => _deletePasskey(security),
            ),
          ],
        ],
      ),
    );
  }
}
