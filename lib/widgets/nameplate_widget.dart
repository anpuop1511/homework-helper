import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Maps a nameplate cosmetic ID to a list of gradient colors.
///
/// Returns an empty list when [id] is empty or unrecognised (= no nameplate).
List<Color> nameplateGradientColors(String id) {
  switch (id) {
    case 'blue_sky':
      return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
    case 'daffodil_yellow':
      return [const Color(0xFFFFEE58), const Color(0xFFFFA000)];
    // Battle-pass reward value (legacy — stored as a human-readable name)
    case 'Cherry Blossom':
      return [const Color(0xFFFF80AB), const Color(0xFFFF4081)];
    case 'animated_golden_cherry_blossom':
      return [const Color(0xFFFFD700), const Color(0xFFFF69B4)];
    case 'aurora_purple':
      return [const Color(0xFFCE93D8), const Color(0xFF7B1FA2)];
    case 'ocean_deep':
      return [const Color(0xFF26C6DA), const Color(0xFF00695C)];
    default:
      return [];
  }
}

/// Returns the text color to use on top of the nameplate gradient.
Color nameplateForegroundColor(String id) {
  switch (id) {
    case 'daffodil_yellow':
      return const Color(0xFF5D4037);
    default:
      return Colors.white;
  }
}

/// Returns the emoji for a badge cosmetic ID, or an empty string when unknown.
///
/// Handles both direct badge IDs (e.g. `'spring_petal_badge'`) and the
/// battle-pass prefixed form (e.g. `'badge_blossom_brawler'`).
String badgeEmoji(String id) {
  switch (id) {
    // ── Season-shop / direct badges ─────────────────────────────────────
    case 'spring_petal_badge':
      return '🌸';
    case 'study_streak_frame':
      return '🔥';
    case 'night_owl_badge':
      return '🦉';
    // ── Battle-pass badges (stored as 'badge_{value}') ──────────────────
    case 'badge_spring_sprout':
      return '🌱';
    case 'badge_blossom_brawler':
      return '🌸';
    case 'badge_petal_collector':
      return '🌼';
    case 'badge_bloom_scholar':
      return '📚';
    case 'badge_blossom_warrior':
      return '⚔️';
    case 'badge_sakura_storm':
      return '🌺';
    case 'badge_petal_warrior':
      return '🌺';
    case 'badge_spring_royale':
      return '👑';
    case 'badge_sakura_legend':
      return '🌟';
    case 'badge_grand_blossom':
      return '🌺';
    default:
      return '';
  }
}

/// Returns the icon string for a Battle Pass type ('plus' → '[+]', 'premium' → '[★]').
///
/// Returns an empty string for the free tier.
String passTypeIcon(String passType) {
  switch (passType) {
    case 'plus':
      return '[+]';
    case 'premium':
      return '[★]';
    default:
      return '';
  }
}

/// Maps a name-color cosmetic ID to a [Color] for the username text.
Color? nameColorValue(String id) {
  switch (id) {
    case 'rainbow_name_color':
      return const Color(0xFFE040FB);
    case 'crimson_name':
      return const Color(0xFFC62828);
    default:
      return null;
  }
}

/// Renders a username (or any text) inside a coloured nameplate background.
///
/// When [nameplateId] is empty or unknown the widget simply returns the [child]
/// (or a plain text of [username]) without any decoration.
class NameplateWidget extends StatelessWidget {
  /// The text to display (typically the user's @handle or display name).
  final String username;

  /// The cosmetic nameplate ID (e.g. `'blue_sky'`). Pass an empty string for
  /// "no nameplate".
  final String nameplateId;

  /// Optional override for font size. Defaults to 12.
  final double fontSize;

  const NameplateWidget({
    super.key,
    required this.username,
    required this.nameplateId,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = nameplateGradientColors(nameplateId);
    if (colors.isEmpty || username.isEmpty) return const SizedBox.shrink();

    final fg = nameplateForegroundColor(nameplateId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        username,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
