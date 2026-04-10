import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/assignments_provider.dart';
import 'settings_screen.dart';

/// The user profile screen showing gamification stats:
/// level, XP progress bar, study streak, and assignment summary.
///
/// Redesigned for Android 16 / Material 3 Expressive style.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserProvider>();
    final assignments = context.watch<AssignmentsProvider>();
    final auth = context.watch<AuthProvider>();

    final completedCount =
        assignments.assignments.where((a) => a.isCompleted).length;
    final totalCount = assignments.assignments.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Header row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Profile',
                      style: GoogleFonts.lexend(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Avatar + Name ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Level ${user.level} Scholar',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (auth.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      auth.email!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Level + XP Card ───────────────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${user.level}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${user.xp} / ${user.xpForNextLevel} XP',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: user.levelProgress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            LinearProgressIndicator(
                          value: value,
                          minHeight: 14,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user.xpForNextLevel - user.xp} XP until Level ${user.level + 1}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats Row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '${user.streak}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          user.streak == 1 ? 'Day Streak' : 'Day Streak 🔥',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '$completedCount',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '${user.totalXp}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Total XP',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Assignment Progress Card ──────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment Progress',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount of $totalCount tasks done',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        totalCount > 0
                            ? '${((completedCount / totalCount) * 100).round()}%'
                            : '0%',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalCount > 0
                          ? completedCount / totalCount
                          : 0,
                      minHeight: 10,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.tertiary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── How XP is Earned ──────────────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Earn XP',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _XpRow(
                    emoji: '✅',
                    label: 'Complete an assignment',
                    xp: '+25 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 8),
                  _XpRow(
                    emoji: '🍅',
                    label: 'Finish a Focus Timer session',
                    xp: '+15 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 8),
                  _XpRow(
                    emoji: '🔥',
                    label: 'Keep your daily streak',
                    xp: '+10 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
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

class _StatCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;

  const _StatCard({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _XpRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String xp;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _XpRow({
    required this.emoji,
    required this.label,
    required this.xp,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: textTheme.bodyMedium),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            xp,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
