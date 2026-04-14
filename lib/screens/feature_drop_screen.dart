import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The unique preference key used to track whether this feature-drop
/// splash has already been shown.  Bump the suffix for each new drop.
const _kShownKey = 'feature_drop_v4_shown';

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
/// Drop update.  Summarises the four major new features:
///   1. Customisable bottom bar (Home always visible + new tabs)
///   2. Subject renaming & class linking
///   3. Google Classroom AI import
///   4. Battle Pass + Season redesign
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
                        'FEATURE DROP',
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
                      "What's New ✨",
                      style: GoogleFonts.lexend(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A batch of powerful new features just landed.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
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
                        emoji: '🧭',
                        title: 'Customisable Navigation',
                        description:
                            'Reorder, hide, or reveal tabs in the bottom bar. '
                            'Home is always pinned, and new Classes & Subjects tabs are now available!',
                        color: colorScheme.primary,
                        onSurface: colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '📚',
                        title: 'Subject Renaming & Linking',
                        description:
                            'Go to Settings → Subjects to rename any subject '
                            '(e.g. "Science" → "Bio"). Then link your classes to those subjects directly.',
                        color: colorScheme.secondary,
                        onSurface: colorScheme.onSecondary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🤖',
                        title: 'AI Classroom Import',
                        description:
                            'Paste your Google Classroom homepage text into the '
                            'new import tool and Gemini will intelligently extract your class names and subjects. '
                            'Requires your Gemini API key in Settings → AI & Models.',
                        color: colorScheme.tertiary,
                        onSurface: colorScheme.onTertiary,
                      ),
                      const SizedBox(height: 12),
                      _FeatureCard(
                        emoji: '🏆',
                        title: 'Battle Pass Redesign',
                        description:
                            'The Season Battle Pass has a fresh new look with '
                            'enhanced reward tiers, smoother progress tracking, and more exciting cosmetics.',
                        color: const Color(0xFFE65100),
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
                      "Let's go! 🚀",
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
