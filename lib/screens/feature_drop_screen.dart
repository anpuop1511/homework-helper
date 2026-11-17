import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The unique preference key used to track whether this feature-drop
/// splash has already been shown.  Bump the suffix for each new drop.
const _kShownKey = 'feature_drop_holiday_shown';

/// Checks (once) whether the Feature Drop screen should be shown, and if so,
/// pushes it as a full-screen route.  Call from a post-frame callback.
Future<void> showFeatureDropIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kShownKey) ?? false) return; // already seen
  await prefs.setBool(_kShownKey, true);
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => const FeatureDropScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}

/// A "What's New" full-screen overlay shown exactly once after the Feature
/// Drop update.  Summarises the December Drop:
///   1. Season 4: Holiday Hustle (Nov 18, 2026 – Jan 1, 2027)
///   2. Cocoa Clash holiday event (Dec 1–25, 2026)
///   3. A real activity feed
///   4. A friends leaderboard
///   5. Holiday profile frames and nameplates
///   6. Smart due-date reminders with a countdown on Home
///   7. Recurring assignment templates
///   8. A "tonight's workload" summary
class FeatureDropScreen extends StatelessWidget {
  const FeatureDropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
                colorScheme.tertiaryContainer,
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // ── Drag handle (visual affordance) ──────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header badge ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'DECEMBER DROP',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "December Drop 🎄",
                      style: GoogleFonts.lexend(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Season 4: Holiday Hustle is here — plus the Cocoa Clash event and a sleigh-full of new features.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '❄️  ❄️  ❄️',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Feature cards ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _FeatureCard(
                        emoji: '🎄',
                        title: 'Season 4: Holiday Hustle',
                        description:
                            'A brand-new season runs Nov 18, 2026 – Jan 1, 2027, with a holiday battle pass full of festive rewards to earn.',
                        color: colorScheme.primary,
                        onSurface: colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '☕',
                        title: 'Cocoa Clash',
                        description:
                            'Our holiday event, Dec 1–25, 2026. Warm up with limited-time challenges and cocoa-themed rewards.',
                        color: const Color(0xFF6D4C41),
                        onSurface: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '📰',
                        title: 'Real Activity Feed',
                        description:
                            'See what your friends are actually up to — completed assignments, streaks, and milestones, live in the feed.',
                        color: colorScheme.secondary,
                        onSurface: colorScheme.onSecondary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🏆',
                        title: 'Friends Leaderboard',
                        description:
                            'Climb the ranks against your friends and see who is really putting in the work this season.',
                        color: const Color(0xFFB8860B),
                        onSurface: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🖼️',
                        title: 'Holiday Frames & Nameplates',
                        description:
                            'Deck out your profile with festive frames and nameplates earned in Season 4 and Cocoa Clash.',
                        color: const Color(0xFF2E7D32),
                        onSurface: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '⏰',
                        title: 'Smart Due-Date Reminders',
                        description:
                            'Gentle reminders with a countdown on Home, so nothing sneaks up on you.',
                        color: colorScheme.tertiary,
                        onSurface: colorScheme.onTertiary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🔁',
                        title: 'Recurring Assignment Templates',
                        description:
                            'Homework that repeats every week? Set it once and it comes back on its own.',
                        color: const Color(0xFFC62828),
                        onSurface: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🌙',
                        title: "Tonight's Workload",
                        description:
                            'A nightly summary of everything due, so you know exactly what to tackle before bed.',
                        color: const Color(0xFF5E35B1),
                        onSurface: Colors.white,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Dismiss button ────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      "Open the December Drop",
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature card widget ───────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final Color onSurface;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
