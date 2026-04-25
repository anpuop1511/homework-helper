import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String _normalizeNameplateId(String id) {
  final trimmed = id.trim();
  if (trimmed.startsWith('nameplate_')) {
    return trimmed.substring('nameplate_'.length);
  }
  return trimmed;
}

/// Maps a nameplate cosmetic ID to a list of gradient colors.
///
/// Returns an empty list when [id] is empty or unrecognised (= no nameplate).
List<Color> nameplateGradientColors(String id) {
  final normalized = _normalizeNameplateId(id);
  switch (normalized) {
    case 'notepad_nameplate':
      return [const Color(0xFFFFF59D), const Color(0xFF42A5F5)];
    case 'blue_sky':
      return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
    case 'daffodil_yellow':
      return [const Color(0xFFFFEE58), const Color(0xFFFFA000)];
    // Battle-pass reward value (legacy — stored as a human-readable name)
    case 'Cherry Blossom':
      return [const Color(0xFFFF80AB), const Color(0xFFFF4081)];
    case 'animated_golden_cherry_blossom':
      return [const Color(0xFFFFD700), const Color(0xFFFF69B4)];
    case 'finals_nameplate':
      return [const Color(0xFF4A148C), const Color(0xFF311B92)];
    case 'finals_glow_card':
      return [const Color(0xFF00E5FF), const Color(0xFF2962FF)];
    case 'honor_roll_card':
      return [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
    case 'glow_name_card':
      return [const Color(0xFFEF9A9A), const Color(0xFFD81B60)];
    case 'exam_master_card':
      return [const Color(0xFFB39DDB), const Color(0xFF512DA8)];
    case 'valedictorian_card':
      return [const Color(0xFFA5D6A7), const Color(0xFF2E7D32)];
    case 'animated_aplus_nameplate':
      return [const Color(0xFFFFD600), const Color(0xFFFF6D00)];
    case 'animated_sharpener_nameplate':
      return [const Color(0xFFFFEB3B), const Color(0xFF212121)];
    case 'aurora_purple':
      return [const Color(0xFFCE93D8), const Color(0xFF7B1FA2)];
    case 'ocean_deep':
      return [const Color(0xFF1565C0), const Color(0xFF001F54)];
    default:
      return [];
  }
}

/// Returns the text color to use on top of the nameplate gradient.
Color nameplateForegroundColor(String id) {
  final normalized = _normalizeNameplateId(id);
  switch (normalized) {
    case 'notepad_nameplate':
      return const Color(0xFF1A237E);
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
      return '💥';
    case 'night_owl_badge':
      return '🦉';
    // ── Battle-pass badges (stored as 'badge_{value}') ──────────────────
    case 'badge_spring_sprout':
      return '🌱';
    case 'badge_blossom_brawler':
      return '🥊';
    case 'badge_petal_collector':
      return '🌼';
    case 'badge_bloom_scholar':
      return '📚';
    case 'badge_blossom_warrior':
      return '⚔️';
    case 'badge_sakura_storm':
      return '🌪️';
    case 'badge_petal_warrior':
      return '🛡️';
    case 'badge_spring_royale':
      return '👑';
    case 'badge_sakura_legend':
      return '🌟';
    case 'badge_grand_blossom':
      return '💮';
    case 'badge_finals_focus':
      return '🎯';
    case 'badge_exam_ace':
      return '🏅';
    case 'badge_top_of_class':
      return '🎓';
    case 'finals_champion_badge':
      return '🏆';
    case 'honor_roll_badge':
      return '🥇';
    case 'all_nighter_badge':
      return '🌃';
    case 'finals_fire_badge':
      return '🔥';
    case 'pencil_badge':
      return '✏️';
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

/// Returns `true` when the nameplate ID uses a looping animation.
bool isAnimatedNameplate(String id) {
  final normalized = _normalizeNameplateId(id);
  return normalized == 'animated_golden_cherry_blossom' ||
      normalized == 'animated_aplus_nameplate' ||
      normalized == 'animated_sharpener_nameplate';
}

/// Renders a username (or any text) inside a coloured nameplate background.
///
/// When [nameplateId] is the Tier-50 animated golden cherry blossom the
/// gradient sweeps continuously left-to-right in a shimmer loop.  All other
/// nameplates render a static linear gradient.
///
/// When [nameplateId] is empty or unknown the widget simply renders plain text.
class NameplateWidget extends StatefulWidget {
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
  State<NameplateWidget> createState() => _NameplateWidgetState();
}

class _NameplateWidgetState extends State<NameplateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (isAnimatedNameplate(widget.nameplateId)) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NameplateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isAnimatedNameplate(widget.nameplateId)) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = nameplateGradientColors(widget.nameplateId);
    if (colors.isEmpty || widget.username.isEmpty) return const SizedBox.shrink();

    final fg = nameplateForegroundColor(widget.nameplateId);
    final animated = isAnimatedNameplate(widget.nameplateId);

    if (animated) {
      return AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          // Sweep the shimmer highlight from left-to-right and back.
          final t = _anim.value;
          final normalizedId = _normalizeNameplateId(widget.nameplateId);
          final List<Color> baseColors =
            normalizedId == 'animated_sharpener_nameplate'
                  ? const [
                      Color(0xFFFFEB3B),
                      Color(0xFFFFC107),
                      Color(0xFF212121),
                      Color(0xFFFFEB3B),
                    ]
              : normalizedId == 'animated_aplus_nameplate'
                      ? const [
                          Color(0xFFFF6D00),
                          Color(0xFFFFC400),
                          Color(0xFF2962FF),
                          Color(0xFFFF6D00),
                        ]
                  : const [
                      Color(0xFFFFD700),
                      Color(0xFFFFB347),
                      Color(0xFFFF69B4),
                      Color(0xFFFFD700),
                    ];
          // Shimmer highlight positioned along the gradient.
          final shimmerPos = t;
          final shimmerColors = [
            baseColors[0],
            Color.lerp(baseColors[1], Colors.white, 0.6 * math.sin(math.pi * shimmerPos))!,
            baseColors[2],
            baseColors[3],
          ];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: shimmerColors,
                begin: Alignment(-1.0 + 2.0 * t, 0),
                end: Alignment(1.0 + 2.0 * t, 0),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: baseColors.first.withAlpha(
                    (80 + 80 * math.sin(math.pi * t)).round(),
                  ),
                  blurRadius: 8 + 4 * t,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Text(
          widget.username,
          style: GoogleFonts.outfit(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      );
    }

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
        widget.username,
        style: GoogleFonts.outfit(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
