import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/assignments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/security_provider.dart';
import '../providers/social_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'username_screen.dart';

/// Email of the developer account that can see the hidden debug menu.
const _kDevEmail = 'anpuop1511@gmail.com';

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
      case 'Developer':
        page = const _DeveloperMenuPage();
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
    final auth = context.watch<AuthProvider>();
    final isDev = auth.email == _kDevEmail;

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
                itemCount: filtered.length + (isDev ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  // Developer tile is always last.
                  if (isDev && i == filtered.length) {
                    const devCat = _CategoryData(
                      icon: Icons.bug_report_rounded,
                      color: Color(0xFFD32F2F),
                      title: 'Developer',
                      subtitle: 'Debug tools — dev only',
                    );
                    return _SettingsCategoryTile(
                      data: devCat,
                      colorScheme: colorScheme,
                      onTap: () => _openCategory(devCat, context),
                    );
                  }
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
        // Only show the username card when the user already has a handle.
        // Handle creation is handled exclusively during sign-up, so there
        // is nothing to "set" afterwards — only to change an existing one.
        if (auth.username != null && auth.username!.isNotEmpty) ...[
          _SquircleCard(
            colorScheme: colorScheme,
            child: Column(
              children: [
                _SecurityTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'Change Username  (@${auth.username})',
                  subtitle: 'Update your unique @handle.',
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
        ],
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
                    SizedBox(
                      width: 160,
                      child: DropdownButton<AiModel>(
                        value: chat.selectedModel,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: AiModel.values.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    m.label,
                                    style: textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (m == AiModel.gemini31FlashLitePreview) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Preview',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (m) {
                          if (m != null) {
                            context.read<ChatProvider>().setModel(m);
                          }
                        },
                      ),
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

  static const _springVibes = {
    AppVibe.springMint,
    AppVibe.cherryBlossom,
    AppVibe.skyBloom,
    AppVibe.daffodil,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final socialProvider = context.watch<SocialProvider>();
    final userProvider = context.watch<UserProvider>();
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
              final isSpring = _springVibes.contains(vibe);
              final cosmeticId = 'vibe_${vibe.name}';
              final isUnlocked = !isSpring ||
                  userProvider.unlockedCosmetics.contains(cosmeticId);
              final vibeScheme = ColorScheme.fromSeed(
                seedColor: vibe.seedColor,
                brightness: Theme.of(context).brightness,
              );
              return _VibeRow(
                vibe: vibe,
                vibeScheme: vibeScheme,
                isSelected: isSelected,
                isLocked: !isUnlocked,
                onTap: () {
                  if (!isUnlocked) {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Row(
                          children: [
                            Text(vibe.emoji),
                            const SizedBox(width: 8),
                            Text(vibe.label),
                          ],
                        ),
                        content: const Text(
                          'This theme is part of the Spring Bloomin\' Battle Pass!\n\n'
                          'Complete Battle Pass tiers or unlock it in the Season Shop.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  context.read<ThemeProvider>().setVibe(vibe);
                },
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
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          _BiometricsSection(colorScheme: colorScheme),
        ],
      ],
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────

const String _kCurrentVersion = '2.7.0';
const String _kGithubReleasesApi =
    'https://api.github.com/repos/anpuop1511/homework-helper/releases/latest';

class _AboutSettingsPage extends StatefulWidget {
  const _AboutSettingsPage();

  @override
  State<_AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<_AboutSettingsPage> {
  bool _checkingUpdate = false;
  String? _updateResult; // null = not checked, '' = up to date, else = new version tag

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingUpdate = true;
      _updateResult = null;
    });
    try {
      // Note: on Flutter Web, browsers block setting the 'User-Agent' header
      // in XHR requests (it is a forbidden request-header name), which causes
      // a DOMException and makes the call fail. Only include it on native.
      final headers = <String, String>{
        'Accept': 'application/vnd.github+json',
        if (!kIsWeb) 'User-Agent': 'homework-helper-app',
      };
      final response = await http
          .get(Uri.parse(_kGithubReleasesApi), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tag = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
        final htmlUrl = data['html_url'] as String? ?? '';
        final body = data['body'] as String? ?? '';
        if (_isNewerVersion(tag, _kCurrentVersion)) {
          // Show update dialog.
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.system_update_rounded,
                      color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Text(
                    'Update Available 🎉',
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v$tag is available (you have v$_kCurrentVersion)',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        body.length > 400
                            ? '${body.substring(0, 400)}…'
                            : body,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later'),
                ),
                FilledButton.icon(
                  onPressed: htmlUrl.isNotEmpty
                      ? () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse(htmlUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        }
                      : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('View Release'),
                ),
              ],
            ),
          );
          if (mounted) setState(() => _updateResult = tag);
        } else {
          if (mounted) setState(() => _updateResult = '');
        }
      } else {
        if (mounted) setState(() => _updateResult = null);
        _showSnack('Could not reach GitHub (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint('[UpdateChecker] _checkForUpdates error: $e\n$st');
      if (mounted) setState(() => _updateResult = null);
      _showSnack('Update check failed: $e');
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  /// Returns true when [latest] is a strictly newer semver string than [current].
  bool _isNewerVersion(String latest, String current) {
    final l = _parseVersion(latest);
    final c = _parseVersion(current);
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String v) {
    // Strip build metadata (+N) and any leading 'v' before splitting.
    final clean = v.replaceFirst(RegExp(r'^v'), '').split('+').first;
    final parts = clean.split('.');
    return List.generate(
        3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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
                subtitle: const Text('Version $_kCurrentVersion'),
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
        const SizedBox(height: 12),
        // ── Check for Updates card ────────────────────────────────────────
        _SquircleCard(
          colorScheme: colorScheme,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _updateResult != null && _updateResult!.isNotEmpty
                    ? const Color(0xFF2E7D32).withAlpha(30)
                    : colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _checkingUpdate
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.tertiary,
                      ),
                    )
                  : Icon(
                      _updateResult != null && _updateResult!.isNotEmpty
                          ? Icons.system_update_rounded
                          : Icons.update_rounded,
                      color: _updateResult != null && _updateResult!.isNotEmpty
                          ? const Color(0xFF2E7D32)
                          : colorScheme.onTertiaryContainer,
                    ),
            ),
            title: Text(
              'Check for Updates',
              style: textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              _checkingUpdate
                  ? 'Checking GitHub releases…'
                  : _updateResult == null
                      ? 'Tap to check for a newer version'
                      : _updateResult!.isEmpty
                          ? 'You\'re up to date ✓'
                          : 'v${_updateResult!} available — tap to view',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            trailing: _checkingUpdate
                ? null
                : Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
            onTap: _checkingUpdate ? null : _checkForUpdates,
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
  final bool isLocked;
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
    this.isLocked = false,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                      if (isLocked)
                        Text(
                          '🔒 Unlock via Battle Pass',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: colorScheme.primary, size: 20),
                if (isLocked && !isSelected)
                  Icon(Icons.lock_rounded,
                      color: colorScheme.onSurfaceVariant, size: 18),
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
      await security.storePasskeyCredentials(email);
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

// ── Developer / Debug Menu ─────────────────────────────────────────────────

/// Hidden settings page only accessible to the dev account
/// ([_kDevEmail] = anpuop1511@gmail.com).
///
/// Provides quick shortcuts to inject rewards, reset state, spawn test data,
/// time-travel the Season Shop, and run through a release-readiness checklist.
class _DeveloperMenuPage extends StatefulWidget {
  const _DeveloperMenuPage();

  @override
  State<_DeveloperMenuPage> createState() => _DeveloperMenuPageState();
}

class _DeveloperMenuPageState extends State<_DeveloperMenuPage> {
  // ── QA Checklist items ──────────────────────────────────────────────────
  static const _qaItems = [
    'Test Auth — sign up / sign in / sign out',
    'Test Battle Pass — view tiers, buy Plus / Premium',
    'Test Checking off Assignment — anti-farming (re-check = no reward)',
    'Test Equipping Badge — cosmetics screen saves & renders on profile',
    'Test Season Shop — buy item, auto-equip, coins deducted',
    'Test Nameplate — renders behind display name on Profile & Social',
    'Test Social / Friends — add friend, view leaderboard',
    'Test AI Chat — ask a homework question, get a response',
    'Test Notifications — schedule & receive a reminder',
    'Test Settings — theme switch, passkey, privacy options',
    'Test Wipe Account — confirm new-user experience from zero',
  ];

  final Set<int> _checked = {};

  // ── Action helpers ──────────────────────────────────────────────────────

  void _grantCoins(BuildContext context) {
    context.read<UserProvider>().awardCoins(1000);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🪙 +1000 Coins granted!')),
    );
  }

  void _grantSeasonXp(BuildContext context) {
    context.read<UserProvider>().addSeasonXp(500);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🌟 +500 Season XP (+5 Tiers) granted!')),
    );
  }

  void _grantAccountXp(BuildContext context) {
    context.read<UserProvider>().awardXp(500);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚡ +500 Account XP granted!')),
    );
  }

  void _maxBattlePass(BuildContext context) {
    context.read<UserProvider>().maxBattlePass();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🏆 Battle Pass maxed to Tier 50!')),
    );
  }

  void _unlockAllCosmetics(BuildContext context) {
    context.read<UserProvider>().unlockAllCosmetics();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎨 All cosmetics unlocked!')),
    );
  }

  void _spawnTestAssignments(BuildContext context) {
    context.read<AssignmentsProvider>().spawnTestAssignments();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📚 5 test assignments spawned!')),
    );
  }

  void _resetPass(BuildContext context) {
    final user = context.read<UserProvider>();
    user.setPassType('free');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Battle Pass reset to Free.')),
    );
  }

  void _wipeAccount(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Wipe Account?'),
        content: const Text(
          'This will reset ALL progress — coins, XP, Battle Pass, cosmetics — '
          'back to day-one state.  You will stay signed in.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await context.read<UserProvider>().resetForTesting();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('💥 Account wiped — fresh start!')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🐛 Developer Menu',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Economy ───────────────────────────────────────────────────
          _DevCard(
            title: 'Economy',
            colorScheme: colorScheme,
            children: [
              _DevButton(
                icon: Icons.monetization_on_rounded,
                label: 'Grant 1000 Coins',
                color: const Color(0xFFFFD700),
                onTap: () => _grantCoins(context),
              ),
              const SizedBox(height: 8),
              _DevButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Grant 500 Season XP (+5 Tiers)',
                color: Colors.purple,
                onTap: () => _grantSeasonXp(context),
              ),
              const SizedBox(height: 8),
              _DevButton(
                icon: Icons.bolt_rounded,
                label: 'Grant 500 Account XP',
                color: Colors.orange,
                onTap: () => _grantAccountXp(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── State Controls ─────────────────────────────────────────────
          _DevCard(
            title: 'State Controls',
            colorScheme: colorScheme,
            children: [
              _DevButton(
                icon: Icons.military_tech_rounded,
                label: 'Max Battle Pass (→ Tier 50)',
                color: Colors.amber,
                onTap: () => _maxBattlePass(context),
              ),
              const SizedBox(height: 8),
              _DevButton(
                icon: Icons.color_lens_rounded,
                label: 'Unlock All Cosmetics',
                color: Colors.teal,
                onTap: () => _unlockAllCosmetics(context),
              ),
              const SizedBox(height: 8),
              _DevButton(
                icon: Icons.refresh_rounded,
                label: 'Reset Battle Pass to Free',
                color: colorScheme.error,
                onTap: () => _resetPass(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── QA Tools ──────────────────────────────────────────────────
          _DevCard(
            title: 'QA Tools',
            colorScheme: colorScheme,
            children: [
              _DevButton(
                icon: Icons.add_task_rounded,
                label: 'Spawn 5 Test Assignments',
                color: Colors.indigo,
                onTap: () => _spawnTestAssignments(context),
              ),
              const SizedBox(height: 8),
              // Time-travel toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withAlpha(80)),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  secondary: const Icon(Icons.access_time_rounded,
                      color: Colors.cyan),
                  title: const Text(
                    'Time-Travel Shop',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Bypasses 4/7/10/12-day timers — all drops available now',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: user.shopTimeTravelEnabled,
                  onChanged: (v) =>
                      context.read<UserProvider>().setShopTimeTravel(v),
                ),
              ),
              const SizedBox(height: 8),
              _DevButton(
                icon: Icons.delete_forever_rounded,
                label: 'Wipe Account (Hard Reset)',
                color: const Color(0xFFD32F2F),
                onTap: () => _wipeAccount(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── QA Release Readiness Checklist ─────────────────────────────
          Card(
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Release Readiness Checklist',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_checked.length}/${_qaItems.length}',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _checked.length == _qaItems.length
                              ? Colors.green
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _qaItems.isEmpty
                        ? 0
                        : _checked.length / _qaItems.length,
                    borderRadius: BorderRadius.circular(4),
                    color: _checked.length == _qaItems.length
                        ? Colors.green
                        : colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                  const SizedBox(height: 12),
                  ..._qaItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    final done = _checked.contains(idx);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() {
                        if (done) {
                          _checked.remove(idx);
                        } else {
                          _checked.add(idx);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              done
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 20,
                              color: done
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: done
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_checked.length == _qaItems.length) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded,
                              color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '✅ All checks passed — ready to release!',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared dev-menu card wrapper ────────────────────────────────────────────

class _DevCard extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _DevCard({
    required this.title,
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DevButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color.withAlpha(30),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withAlpha(80)),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
