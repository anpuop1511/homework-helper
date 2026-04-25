import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/nameplate_widget.dart';

/// A screen where users can equip their owned cosmetics.
///
/// Shows three categories:
///   • Nameplates  (equip one visual plate behind username)
///   • Badges      (equip one badge shown on profile)
///   • Name Colors (equip one name color)
class CosmeticsScreen extends StatelessWidget {
  const CosmeticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Cosmetics 🎨',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: const _CosmeticsBody(),
    );
  }
}

// ── Cosmetic catalogue ──────────────────────────────────────────────────────

enum _CosmeticType { nameplate, badge, nameColor }

class _CosmeticInfo {
  final String id;
  final String label;
  final String emoji;
  final _CosmeticType type;

  const _CosmeticInfo({
    required this.id,
    required this.label,
    required this.emoji,
    required this.type,
  });
}

/// All cosmetics that can be equipped (must match shop / battle-pass IDs).
const _allCosmetics = [
  _CosmeticInfo(
    id: 'notepad_nameplate',
    label: 'Notepad Nameplate',
    emoji: '📝',
    type: _CosmeticType.nameplate,
  ),
  // ── Nameplates ──────────────────────────────────────────────────────
  _CosmeticInfo(
    id: 'blue_sky',
    label: 'Blue Sky',
    emoji: '🩵',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'daffodil_yellow',
    label: 'Daffodil Yellow',
    emoji: '🌼',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'Cherry Blossom',
    label: 'Cherry Blossom',
    emoji: '🌸',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'animated_golden_cherry_blossom',
    label: 'Golden Cherry Blossom',
    emoji: '🌟',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'aurora_purple',
    label: 'Aurora Purple',
    emoji: '💜',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'ocean_deep',
    label: 'Ocean Deep',
    emoji: '🌊',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'finals_nameplate',
    label: 'Finals Nameplate',
    emoji: '🎓',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'animated_aplus_nameplate',
    label: 'Animated A+ Nameplate',
    emoji: '🅰️',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'finals_glow_card',
    label: 'Finals Glow Card',
    emoji: '🃏',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'honor_roll_card',
    label: 'Honor Roll Card',
    emoji: '🪪',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'glow_name_card',
    label: 'Glow Name Card',
    emoji: '💫',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'exam_master_card',
    label: 'Exam Master Card',
    emoji: '📘',
    type: _CosmeticType.nameplate,
  ),
  _CosmeticInfo(
    id: 'valedictorian_card',
    label: 'Valedictorian Card',
    emoji: '🏅',
    type: _CosmeticType.nameplate,
  ),
  // ── Badges (Season Shop) ────────────────────────────────────────────
  _CosmeticInfo(
    id: 'spring_petal_badge',
    label: 'Spring Petal',
    emoji: '🌸',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'study_streak_frame',
    label: 'Study Streak',
    emoji: '💥',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'night_owl_badge',
    label: 'Night Owl',
    emoji: '🦉',
    type: _CosmeticType.badge,
  ),
  // ── Badges (Battle Pass — Free Track) ──────────────────────────────
  _CosmeticInfo(
    id: 'badge_spring_sprout',
    label: 'Spring Sprout',
    emoji: '🌱',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_blossom_brawler',
    label: 'Blossom Brawler',
    emoji: '🥊',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_petal_collector',
    label: 'Petal Collector',
    emoji: '🌼',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_bloom_scholar',
    label: 'Bloom Scholar',
    emoji: '📚',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_blossom_warrior',
    label: 'Blossom Warrior',
    emoji: '⚔️',
    type: _CosmeticType.badge,
  ),
  // ── Badges (Battle Pass — Premium Track) ───────────────────────────
  _CosmeticInfo(
    id: 'badge_sakura_storm',
    label: 'Sakura Storm',
    emoji: '🌪️',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_petal_warrior',
    label: 'Petal Warrior',
    emoji: '🛡️',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_spring_royale',
    label: 'Spring Royale',
    emoji: '👑',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_sakura_legend',
    label: 'Sakura Legend',
    emoji: '🌟',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_grand_blossom',
    label: 'Grand Blossom',
    emoji: '💮',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_finals_focus',
    label: 'Finals Focus',
    emoji: '🎯',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_exam_ace',
    label: 'Exam Ace',
    emoji: '🏅',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'badge_top_of_class',
    label: 'Top of Class',
    emoji: '🎓',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'finals_champion_badge',
    label: 'Finals Champion',
    emoji: '🏆',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'honor_roll_badge',
    label: 'Honor Roll',
    emoji: '🥇',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'all_nighter_badge',
    label: 'All-Nighter',
    emoji: '🌃',
    type: _CosmeticType.badge,
  ),
  _CosmeticInfo(
    id: 'finals_fire_badge',
    label: 'Finals Fire',
    emoji: '🔥',
    type: _CosmeticType.badge,
  ),
  // ── Name Colors ─────────────────────────────────────────────────────
  _CosmeticInfo(
    id: 'rainbow_name_color',
    label: 'Rainbow',
    emoji: '🌈',
    type: _CosmeticType.nameColor,
  ),
  _CosmeticInfo(
    id: 'crimson_name',
    label: 'Crimson',
    emoji: '🔴',
    type: _CosmeticType.nameColor,
  ),
];

// ── Body ────────────────────────────────────────────────────────────────────

/// Returns true if a cosmetic [id] is in the user's [owned] list.
///
/// Handles both direct IDs (e.g. `'blue_sky'`) and the legacy battle-pass
/// prefixed form (e.g. `'nameplate_Cherry Blossom'`) stored by earlier app
/// versions.
bool _isOwned(List<String> owned, _CosmeticInfo c) {
  if (owned.contains(c.id)) return true;
  // Legacy battle-pass prefix e.g. 'nameplate_Cherry Blossom'
  if (c.type == _CosmeticType.nameplate &&
      owned.contains('nameplate_${c.id}')) {
    return true;
  }
  return false;
}

class _CosmeticsBody extends StatelessWidget {
  const _CosmeticsBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final owned = user.unlockedCosmetics;

    final nameplates = _allCosmetics
        .where((c) => c.type == _CosmeticType.nameplate && _isOwned(owned, c))
        .toList();
    final badges = _allCosmetics
        .where((c) => c.type == _CosmeticType.badge && _isOwned(owned, c))
        .toList();
    final nameColors = _allCosmetics
        .where(
            (c) => c.type == _CosmeticType.nameColor && _isOwned(owned, c))
        .toList();

    if (nameplates.isEmpty && badges.isEmpty && nameColors.isEmpty) {
      return _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (nameplates.isNotEmpty) ...[
          _SectionHeader(title: 'Nameplates', icon: Icons.rectangle_rounded),
          const SizedBox(height: 8),
          ...nameplates.map((c) => _CosmeticTile(
                cosmetic: c,
                equipped: user.activeNameplate == c.id,
                onEquip: () => _equip(context, user, c),
                onUnequip: () => user.equipNameplate(''),
              )),
          const SizedBox(height: 16),
        ],
        if (badges.isNotEmpty) ...[
          _SectionHeader(title: 'Badges', icon: Icons.military_tech_rounded),
          const SizedBox(height: 8),
          ...badges.map((c) => _CosmeticTile(
                cosmetic: c,
                equipped: user.equippedBadge == c.id,
                onEquip: () => _equip(context, user, c),
                onUnequip: () => user.equipBadge(''),
              )),
          const SizedBox(height: 16),
        ],
        if (nameColors.isNotEmpty) ...[
          _SectionHeader(
              title: 'Name Colors', icon: Icons.color_lens_rounded),
          const SizedBox(height: 8),
          ...nameColors.map((c) => _CosmeticTile(
                cosmetic: c,
                equipped: user.equippedNameColor == c.id,
                onEquip: () => _equip(context, user, c),
                onUnequip: () => user.equipNameColor(''),
              )),
        ],
      ],
    );
  }

  void _equip(
    BuildContext context,
    UserProvider user,
    _CosmeticInfo cosmetic,
  ) {
    // Safety: only owned items can be equipped.
    // Use _isOwned to handle both direct IDs and legacy battle-pass prefixed IDs.
    if (!_isOwned(user.unlockedCosmetics, cosmetic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You don\'t own this item yet. Buy it in the Season Shop!')),
      );
      return;
    }

    switch (cosmetic.type) {
      case _CosmeticType.nameplate:
        user.equipNameplate(cosmetic.id);
      case _CosmeticType.badge:
        user.equipBadge(cosmetic.id);
      case _CosmeticType.nameColor:
        user.equipNameColor(cosmetic.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cosmetic.emoji} ${cosmetic.label} equipped!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Tile ────────────────────────────────────────────────────────────────────

class _CosmeticTile extends StatelessWidget {
  final _CosmeticInfo cosmetic;
  final bool equipped;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;

  const _CosmeticTile({
    required this.cosmetic,
    required this.equipped,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: equipped
            ? colorScheme.primaryContainer.withAlpha(120)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: equipped
              ? colorScheme.primary.withAlpha(160)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Preview
          if (cosmetic.type == _CosmeticType.nameplate)
            NameplateWidget(
              username: 'Preview',
              nameplateId: cosmetic.id,
              fontSize: 12,
            )
          else if (cosmetic.type == _CosmeticType.nameColor)
            Text(
              'Aa',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: nameColorValue(cosmetic.id) ?? colorScheme.primary,
              ),
            )
          else
            Text(cosmetic.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              cosmetic.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (equipped)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✓ Equipped',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onUnequip,
                  child: const Text('Remove'),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: onEquip,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Equip'),
            ),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎭', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No cosmetics yet!',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visit the Season Shop to unlock nameplates, badges, and name colors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
