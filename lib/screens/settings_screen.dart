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

/// Settings screen – Android 16 / Material 3 Expressive style.
///
/// Sections:
///   - 🎨 Personalization  (App Vibe)
///   - 🏷️ Identity         (username)
///   - 🔒 Privacy & Security (study activity, chat history, AI permissions,
///                            data export, biometric lock, NFC biometric,
///                            passkey, change password, email verification)
///   - ℹ️  About            (version, device type)
///   - Sign Out
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final socialProvider = context.watch<SocialProvider>();
    final security = context.watch<SecurityProvider>();
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

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
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Large Bold Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Settings',
                style: GoogleFonts.lexend(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              'Customise your experience.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // ── 🎨 Personalization ────────────────────────────────────
            _SectionLabel(
                label: '🎨  Personalization', colorScheme: colorScheme),
            const SizedBox(height: 4),
            Text(
              'Choose a color palette that matches your mood.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
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
                    onTap: () =>
                        context.read<ThemeProvider>().setVibe(vibe),
                    showDivider: vibe != AppVibe.values.last,
                    colorScheme: colorScheme,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // ── 🏷️ Identity ───────────────────────────────────────────
            _SectionLabel(label: '🏷️  Identity', colorScheme: colorScheme),
            const SizedBox(height: 10),
            _SquircleCard(
              colorScheme: colorScheme,
              child: _SecurityTile(
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
            ),
            const SizedBox(height: 28),

            // ── 🔒 Privacy & Security ─────────────────────────────────
            _SectionLabel(
                label: '🔒  Privacy & Security',
                colorScheme: colorScheme),
            const SizedBox(height: 10),

            // Privacy sub-card
            _SquircleCard(
              colorScheme: colorScheme,
              child: Column(
                children: [
                  // Show Study Activity
                  SwitchListTile(
                    value: socialProvider.showStudyActivity,
                    onChanged: (v) =>
                        context
                            .read<SocialProvider>()
                            .setShowStudyActivity(v),
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people_rounded,
                          color: colorScheme.onSecondaryContainer,
                          size: 20),
                    ),
                    title: Text(
                      'Show Study Activity to Friends',
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Let friends see when you are in a focus session.',
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withAlpha(100)),

                  // Ghost Mode (Pause History)
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
                      child: Center(
                        child: Text(
                          '👻',
                          style: const TextStyle(fontSize: 20),
                        ),
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
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withAlpha(100)),

                  // Revoke AI Permissions
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
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant),
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
                  Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withAlpha(100)),

                  // Data Export
                  _SecurityTile(
                    icon: Icons.file_download_rounded,
                    title: 'Export My Data',
                    subtitle: 'Download a copy of your data.',
                    colorScheme: colorScheme,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Data export coming soon.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Security sub-card
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
                        ? 'Your email is verified ✅'
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

            // Biometrics & Passkey sub-card
            _BiometricsSection(colorScheme: colorScheme),
            const SizedBox(height: 28),

            // ── ℹ️  About ─────────────────────────────────────────────
            _SectionLabel(label: 'ℹ️  About', colorScheme: colorScheme),
            const SizedBox(height: 10),
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
                    subtitle: const Text('Version 2.4.0'),
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
            const SizedBox(height: 32),

            // ── Sign Out ──────────────────────────────────────────────
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Returns a short human-readable device / platform label.
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

  Future<void> _confirmClearChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onErrorContainer,
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

// ── Shared sub-widgets ───────────────────────────────────────────────────────

/// Large section label following Android 16 style.
class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _SectionLabel({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

/// Biometrics & Passkey section — stateful because it triggers async flows.
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
    // First, prompt the user for their password so we can store credentials
    // that will be used to re-authenticate with Firebase when using the Passkey.
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

    // Verify the password with Firebase before registering the passkey.
    final authProvider =
        context.read<AuthProvider>();
    try {
      await authProvider.verifyCurrentPassword(password);
    } catch (_) {
      if (!mounted) return;
      setState(() => _setupLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect password. Passkey setup cancelled.'),
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
              'Require biometrics when returning to the app.',
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
                      child: CircularProgressIndicator(strokeWidth: 2))
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
                'Passkey Active ✅',
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
                height: 1, color: cs.outlineVariant.withAlpha(100)),
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
                      child: CircularProgressIndicator(strokeWidth: 2))
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
