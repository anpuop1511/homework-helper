import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Settings screen with an app theme "Vibe" picker.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Theme Section ────────────────────────────────────────────
          Text(
            'App Vibe',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a color palette that matches your mood.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...AppVibe.values.map(
            (vibe) => _VibeOption(
              vibe: vibe,
              isSelected: themeProvider.vibe == vibe,
              onTap: () => context.read<ThemeProvider>().setVibe(vibe),
            ),
          ),
          const SizedBox(height: 32),

          // ── About Section ────────────────────────────────────────────
          Text(
            'About',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              'Homework Helper',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Version 1.0.0',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeOption extends StatelessWidget {
  final AppVibe vibe;
  final bool isSelected;
  final VoidCallback onTap;

  const _VibeOption({
    required this.vibe,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Build a mini color swatch from the vibe seed color
    final vibeScheme = ColorScheme.fromSeed(
      seedColor: vibe.seedColor,
      brightness: Theme.of(context).brightness,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? vibeScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? vibeScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color swatch dots
            Row(
              children: [
                _SwatchDot(color: vibeScheme.primary),
                const SizedBox(width: 4),
                _SwatchDot(color: vibeScheme.secondary),
                const SizedBox(width: 4),
                _SwatchDot(color: vibeScheme.tertiary),
              ],
            ),
            const SizedBox(width: 14),
            Text(
              vibe.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                vibe.label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? vibeScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: vibeScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  const _SwatchDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
