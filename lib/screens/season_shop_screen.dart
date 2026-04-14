import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/nameplate_widget.dart';

/// A shop where players can spend coins on cosmetic items.
///
/// Items are split into:
///   • **Available now** – purchasable immediately (or already owned)
///   • **Coming soon**  – locked behind a time-gate with a live countdown
class SeasonShopScreen extends StatelessWidget {
  const SeasonShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Season Shop 🛒',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: const _ShopBody(),
    );
  }
}

// ── Cosmetic type ────────────────────────────────────────────────────────────

enum _CosmeticType { badge, nameplate, nameColor }

// ── Shop item models ─────────────────────────────────────────────────────────

class _ShopItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int price;
  final _CosmeticType cosmeticType;

  const _ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.price,
    required this.cosmeticType,
  });
}

class _TimedShopItem extends _ShopItem {
  /// When this item becomes purchasable.
  final DateTime unlocksAt;

  const _TimedShopItem({
    required super.id,
    required super.name,
    required super.description,
    required super.emoji,
    required super.price,
    required super.cosmeticType,
    required this.unlocksAt,
  });

  bool get isUnlocked => DateTime.now().isAfter(unlocksAt);
}

// ── Season drop schedule ─────────────────────────────────────────────────────
//
// A single fixed "season start" anchors the 4-drop cadence so timers are
// deterministic across all sessions and devices.
//
// Drop cadence (from season start):
//   Drop A  +4 days
//   Drop B  +7 days  (4 + 3)
//   Drop C  +10 days (4 + 3 + 3)
//   Drop D  +12 days (4 + 3 + 3 + 2)

final _kSeasonDropStart = DateTime.utc(2026, 4, 14); // April 14 2026 00:00 UTC

final _timedDropItems = [
  _TimedShopItem(
    id: 'aurora_purple',
    name: 'Aurora Purple Nameplate',
    description: 'A dreamy purple-gradient plate behind your name.',
    emoji: '💜',
    price: 220,
    cosmeticType: _CosmeticType.nameplate,
    unlocksAt: _kSeasonDropStart.add(const Duration(days: 4)),
  ),
  _TimedShopItem(
    id: 'night_owl_badge',
    name: 'Night Owl Badge',
    description: 'Show off your late-night study sessions.',
    emoji: '🦉',
    price: 180,
    cosmeticType: _CosmeticType.badge,
    unlocksAt: _kSeasonDropStart.add(const Duration(days: 7)), // +3
  ),
  _TimedShopItem(
    id: 'crimson_name',
    name: 'Crimson Name Color',
    description: 'Make your username glow in bold crimson.',
    emoji: '🔴',
    price: 250,
    cosmeticType: _CosmeticType.nameColor,
    unlocksAt: _kSeasonDropStart.add(const Duration(days: 10)), // +3
  ),
  _TimedShopItem(
    id: 'ocean_deep',
    name: 'Ocean Deep Nameplate',
    description: 'A deep teal-to-cyan plate, calm as the sea.',
    emoji: '🌊',
    price: 220,
    cosmeticType: _CosmeticType.nameplate,
    unlocksAt: _kSeasonDropStart.add(const Duration(days: 12)), // +2
  ),
];

// ── Always-available items ────────────────────────────────────────────────────

const _permanentItems = [
  _ShopItem(
    id: 'spring_petal_badge',
    name: 'Spring Petal Badge',
    description: 'A delicate cherry blossom badge for your profile.',
    emoji: '🌸',
    price: 150,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    id: 'blue_sky',
    name: 'Blue Sky Nameplate',
    description: 'A serene sky-blue plate behind your username.',
    emoji: '🩵',
    price: 200,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    id: 'daffodil_yellow',
    name: 'Daffodil Yellow Nameplate',
    description: 'A bright daffodil-yellow plate behind your username.',
    emoji: '🌼',
    price: 200,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    id: 'study_streak_frame',
    name: 'Study Streak Badge',
    description: 'Show off your dedication with a flame-bordered badge.',
    emoji: '🔥',
    price: 250,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    id: 'rainbow_name_color',
    name: 'Rainbow Name Color',
    description: 'Make your name shine in vibrant purple-rainbow.',
    emoji: '🌈',
    price: 300,
    cosmeticType: _CosmeticType.nameColor,
  ),
];

// ── Shop body ────────────────────────────────────────────────────────────────

class _ShopBody extends StatelessWidget {
  const _ShopBody();

  void _purchase(BuildContext context, _ShopItem item) {
    final user = context.read<UserProvider>();

    if (user.unlockedCosmetics.contains(item.id)) {
      _autoEquip(context, user, item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.emoji} ${item.name} equipped!')),
      );
      return;
    }

    final success = user.spendCoins(item.price);
    if (success) {
      user.unlockCosmetic(item.id);
      _autoEquip(context, user, item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.emoji} ${item.name} purchased!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins! Need ${item.price} 🪙 (have ${user.coins})'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  void _autoEquip(BuildContext context, UserProvider user, _ShopItem item) {
    switch (item.cosmeticType) {
      case _CosmeticType.nameplate:
        user.equipNameplate(item.id);
      case _CosmeticType.badge:
        user.equipBadge(item.id);
      case _CosmeticType.nameColor:
        user.equipNameColor(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final unlockedDrops =
        _timedDropItems.where((i) => i.isUnlocked).toList();
    final lockedDrops =
        _timedDropItems.where((i) => !i.isUnlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Coin balance header ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.coins} Coins',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Earn coins by completing assignments & leveling up',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Available Now ──────────────────────────────────────────────
        _SectionHeader(
          title: 'Available Now',
          subtitle: 'Spring Collection — limited this season!',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        ..._permanentItems.map((item) {
          final owned = user.unlockedCosmetics.contains(item.id);
          final equipped = _isEquipped(user, item);
          return _ShopItemCard(
            item: item,
            owned: owned,
            equipped: equipped,
            colorScheme: colorScheme,
            onTap: () => _purchase(context, item),
          );
        }),

        // Unlocked timed drops (available to buy)
        if (unlockedDrops.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...unlockedDrops.map((item) {
            final owned = user.unlockedCosmetics.contains(item.id);
            final equipped = _isEquipped(user, item);
            return _ShopItemCard(
              item: item,
              owned: owned,
              equipped: equipped,
              colorScheme: colorScheme,
              onTap: () => _purchase(context, item),
            );
          }),
        ],

        // ── Coming Soon ────────────────────────────────────────────────
        if (lockedDrops.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Coming Soon',
            subtitle: 'New drops unlock automatically — stay tuned!',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          ...lockedDrops.map((item) => _LockedItemCard(
                item: item,
                colorScheme: colorScheme,
              )),
        ],
      ],
    );
  }

  bool _isEquipped(UserProvider user, _ShopItem item) {
    switch (item.cosmeticType) {
      case _CosmeticType.nameplate:
        return user.activeNameplate == item.id;
      case _CosmeticType.badge:
        return user.equippedBadge == item.id;
      case _CosmeticType.nameColor:
        return user.equippedNameColor == item.id;
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
              fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Available item card ───────────────────────────────────────────────────────

class _ShopItemCard extends StatelessWidget {
  final _ShopItem item;
  final bool owned;
  final bool equipped;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ShopItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: owned
            ? colorScheme.secondaryContainer.withAlpha(80)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: owned
              ? colorScheme.secondary.withAlpha(120)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Preview
          _ItemPreview(item: item),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant),
                ),
                if (equipped) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ Currently equipped',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          owned
              ? FilledButton.tonal(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: Text(equipped ? 'Equipped' : 'Equip'),
                )
              : FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: Text('${item.price} 🪙'),
                ),
        ],
      ),
    );
  }
}

// ── Item preview ─────────────────────────────────────────────────────────────

class _ItemPreview extends StatelessWidget {
  final _ShopItem item;
  const _ItemPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.cosmeticType == _CosmeticType.nameplate) {
      return NameplateWidget(
        username: 'Preview',
        nameplateId: item.id,
        fontSize: 11,
      );
    }
    if (item.cosmeticType == _CosmeticType.nameColor) {
      final col = nameColorValue(item.id);
      return Text(
        'Aa',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: col ?? Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return Text(item.emoji, style: const TextStyle(fontSize: 32));
  }
}

// ── Locked/timed drop card ────────────────────────────────────────────────────

class _LockedItemCard extends StatefulWidget {
  final _TimedShopItem item;
  final ColorScheme colorScheme;

  const _LockedItemCard({
    required this.item,
    required this.colorScheme,
  });

  @override
  State<_LockedItemCard> createState() => _LockedItemCardState();
}

class _LockedItemCardState extends State<_LockedItemCard> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.item.unlocksAt.difference(now);
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d == Duration.zero) return 'Unlocking soon…';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Blurred / greyed-out preview
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: _ItemPreview(item: widget.item),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.description,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.lock_clock_rounded,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatCountdown(_remaining),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.item.price} 🪙',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withAlpha(120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

