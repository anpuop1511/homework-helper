import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

/// Centralized theme configuration for the Homework Helper app.
/// Uses Material 3 Expressive design with vibrant colors and modern typography.
/// Supports multiple color "Vibes" via [AppVibe] and Material You dynamic colour.
class AppTheme {
  AppTheme._();

  /// Returns a light [ThemeData] for the given [vibe].
  /// When [dynamicScheme] is provided (Android 12+ / Material You), it is
  /// used instead of the seed-generated scheme.
  static ThemeData lightTheme([
    AppVibe vibe = AppVibe.defaultPurple,
    ColorScheme? dynamicScheme,
  ]) {
    final colorScheme = dynamicScheme ??
        _colorSchemeForVibe(vibe, Brightness.light);
    return _buildTheme(colorScheme);
  }

  /// Returns a dark [ThemeData] for the given [vibe].
  /// When [dynamicScheme] is provided (Android 12+ / Material You), it is
  /// used instead of the seed-generated scheme.
  static ThemeData darkTheme([
    AppVibe vibe = AppVibe.defaultPurple,
    ColorScheme? dynamicScheme,
  ]) {
    final colorScheme = dynamicScheme ??
        _colorSchemeForVibe(vibe, Brightness.dark);
    return _buildTheme(colorScheme);
  }

  /// Returns a [ColorScheme] for the given [vibe] and [brightness].
  ///
  /// Special vibes (Cyberpunk, Sakura, Midnight) blend a custom hand-crafted
  /// palette on top of a seed-generated base; all others use [ColorScheme.fromSeed]
  /// directly.
  static ColorScheme _colorSchemeForVibe(AppVibe vibe, Brightness brightness) {
    switch (vibe) {
      // ── Cyberpunk: OLED-friendly black + neon pink/cyan ──────────────
      case AppVibe.cyberpunk:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0080),
          brightness: Brightness.dark, // always dark for cyberpunk
        );
        return base.copyWith(
          brightness: brightness,
          primary: const Color(0xFFFF0080),           // neon pink
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFF7A003D),
          onPrimaryContainer: const Color(0xFFFFB3D1),
          secondary: const Color(0xFF00E5FF),          // neon cyan
          onSecondary: Colors.black,
          secondaryContainer: const Color(0xFF006070),
          onSecondaryContainer: const Color(0xFFB3F0FF),
          tertiary: const Color(0xFFCCFF00),            // acid green
          onTertiary: Colors.black,
          tertiaryContainer: const Color(0xFF3D4F00),
          onTertiaryContainer: const Color(0xFFEEFF99),
          surface: brightness == Brightness.dark
              ? const Color(0xFF050505)    // true OLED black
              : const Color(0xFF1A0020),
          onSurface: const Color(0xFFF0F0F0),
          onSurfaceVariant: const Color(0xFFBBAACC),
          outline: const Color(0xFF66004D),
          outlineVariant: const Color(0xFF330028),
        );

      // ── Sakura: soft pink & white pastel ─────────────────────────────
      case AppVibe.sakura:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8FAB),
          brightness: brightness,
        );
        return base.copyWith(
          primary: brightness == Brightness.dark
              ? const Color(0xFFFFB0CE)
              : const Color(0xFFB5006E),
          onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
          primaryContainer: brightness == Brightness.dark
              ? const Color(0xFF880050)
              : const Color(0xFFFFD8EA),
          onPrimaryContainer: brightness == Brightness.dark
              ? const Color(0xFFFFD8EA)
              : const Color(0xFF3E001F),
          surface: brightness == Brightness.dark
              ? const Color(0xFF1F1118)
              : const Color(0xFFFFF8F9),
          onSurface: brightness == Brightness.dark
              ? const Color(0xFFFFECF1)
              : const Color(0xFF22001A),
        );

      // ── Midnight: true black for OLED screens ────────────────────────
      case AppVibe.midnight:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: brightness,
        );
        return base.copyWith(
          surface: brightness == Brightness.dark
              ? Colors.black          // true OLED black
              : const Color(0xFFF5F5FF),
        );

      // ── Neon Sunrise: vivid orange-to-magenta sunrise palette ────────
      case AppVibe.neonSunrise:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
          brightness: brightness,
        );
        return base.copyWith(
          primary: brightness == Brightness.dark
              ? const Color(0xFFFF9A3C)
              : const Color(0xFFD44000),
          onPrimary: Colors.white,
          primaryContainer: brightness == Brightness.dark
              ? const Color(0xFF8C2800)
              : const Color(0xFFFFDCC8),
          onPrimaryContainer: brightness == Brightness.dark
              ? const Color(0xFFFFDCC8)
              : const Color(0xFF3D0900),
          secondary: brightness == Brightness.dark
              ? const Color(0xFFFF5FA3)
              : const Color(0xFFB5004D),
          onSecondary: Colors.white,
          surface: brightness == Brightness.dark
              ? const Color(0xFF1A0E00)
              : const Color(0xFFFFF8F5),
        );

      // ── Deep Ocean: rich deep-blue with teal accents ─────────────────
      case AppVibe.deepOcean:
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFF003D8F),
          brightness: brightness,
        );
        return base.copyWith(
          primary: brightness == Brightness.dark
              ? const Color(0xFF82AFFF)
              : const Color(0xFF003D8F),
          onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
          primaryContainer: brightness == Brightness.dark
              ? const Color(0xFF002B6E)
              : const Color(0xFFD6E3FF),
          onPrimaryContainer: brightness == Brightness.dark
              ? const Color(0xFFD6E3FF)
              : const Color(0xFF001948),
          secondary: brightness == Brightness.dark
              ? const Color(0xFF4ADFE0)
              : const Color(0xFF005F60),
          onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
          surface: brightness == Brightness.dark
              ? const Color(0xFF00080F)   // near-black deep navy
              : const Color(0xFFF5F8FF),
          onSurface: brightness == Brightness.dark
              ? const Color(0xFFDDE3FF)
              : const Color(0xFF001048),
        );

      // ── All other vibes: standard Material 3 seed scheme ─────────────
      default:
        return ColorScheme.fromSeed(
          seedColor: vibe.seedColor,
          brightness: brightness,
        );
    }
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        // Squircle-ish shape via continuous rectangle
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
      ),
      appBarTheme: AppBarTheme(
        // Glassmorphism-style: slightly transparent surface with blur handled
        // per-screen via BackdropFilter where desired.
        backgroundColor: colorScheme.surface.withAlpha(230),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: colorScheme.primary,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withAlpha(230),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          // Squircle-friendly radius
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.lexend(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.lexend(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.lexend(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.lexend(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.lexend(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.lexend(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        // Squircle-inspired radius
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      color: colorScheme.surface,
    );
  }
}
