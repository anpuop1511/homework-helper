import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../providers/theme_provider.dart';

/// Settings screen – Android 16 / Material 3 Expressive style.
///
/// Sections:
///   - App Vibe (theme picker)
///   - Privacy  (show study activity toggle)
///   - Security (change password, email verification)
///   - About
///   - Sign Out
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final socialProvider = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Large Bold Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
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

            // ── App Vibe ──────────────────────────────────────────────
            _SectionLabel(label: '🎨  App Vibe', colorScheme: colorScheme),
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

            // ── Privacy ───────────────────────────────────────────────
            _SectionLabel(label: '🔒  Privacy', colorScheme: colorScheme),
            const SizedBox(height: 10),
            _SquircleCard(
              colorScheme: colorScheme,
              child: SwitchListTile(
                value: socialProvider.showStudyActivity,
                onChanged: (v) =>
                    context.read<SocialProvider>().setShowStudyActivity(v),
                contentPadding: EdgeInsets.zero,
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
            ),
            const SizedBox(height: 28),

            // ── Security ──────────────────────────────────────────────
            _SectionLabel(label: '🛡️  Security', colorScheme: colorScheme),
            const SizedBox(height: 10),
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
            const SizedBox(height: 28),

            // ── About ─────────────────────────────────────────────────
            _SectionLabel(label: 'ℹ️  About', colorScheme: colorScheme),
            const SizedBox(height: 10),
            _SquircleCard(
              colorScheme: colorScheme,
              child: ListTile(
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
                subtitle: const Text('Version 2.2.0'),
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
