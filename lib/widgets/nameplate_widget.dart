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
