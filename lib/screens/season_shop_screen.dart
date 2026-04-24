import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/season_live_ops.dart';
import '../providers/dev_clock_provider.dart';
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
  final String seasonId;
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int price;
  final _CosmeticType cosmeticType;

  const _ShopItem({
    required this.seasonId,
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
    required super.seasonId,
    required super.id,
    required super.name,
    required super.description,
    required super.emoji,
    required super.price,
    required super.cosmeticType,
    required this.unlocksAt,
  });

  bool get isUnlocked => !DateTime.now().toUtc().isBefore(unlocksAt.toUtc());

  /// Whether the item is unlocked relative to the given UTC instant.
  /// Use this to respect the dev clock override.
  bool isUnlockedAt(DateTime utcNow) =>
      !utcNow.isBefore(unlocksAt.toUtc());
}

const _season1PermanentItems = [
  _ShopItem(
    seasonId: 'season_1',
    id: 'spring_petal_badge',
    name: 'Spring Petal Badge',
    description: 'A delicate cherry blossom badge for your profile.',
    emoji: '🌸',
    price: 150,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'blue_sky',
    name: 'Blue Sky Nameplate',
    description: 'A serene sky-blue plate behind your username.',
    emoji: '🩵',
    price: 200,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'daffodil_yellow',
    name: 'Daffodil Yellow Nameplate',
    description: 'A bright daffodil-yellow plate behind your username.',
    emoji: '🌼',
    price: 200,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'study_streak_frame',
    name: 'Study Streak Badge',
    description: 'Show off your dedication with a flame-bordered badge.',
    emoji: '🔥',
    price: 250,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'rainbow_name_color',
    name: 'Rainbow Name Color',
    description: 'Make your name shine in vibrant purple-rainbow.',
    emoji: '🌈',
    price: 300,
    cosmeticType: _CosmeticType.nameColor,
  ),
];

const _season2PermanentItems = [
  _ShopItem(
    seasonId: 'season_2',
    id: 'finals_champion_badge',
    name: 'Finals Champion Badge',
    description: 'A badge for conquering finals week.',
    emoji: '🏆',
    price: 240,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_2',
    id: 'honor_roll_badge',
    name: 'Honor Roll Badge',
    description: 'Show your top-tier study grind.',
    emoji: '🥇',
    price: 220,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_2',
    id: 'glow_name_card',
    name: 'Glow Name Card',
    description: 'A glowing battle-card style plate around your name.',
    emoji: '🃏',
    price: 280,
    cosmeticType: _CosmeticType.nameplate,
  ),
];

const _season1TimedTemplates = [
  _ShopItem(
    seasonId: 'season_1',
    id: 'aurora_purple',
    name: 'Aurora Purple Nameplate',
    description: 'A dreamy purple-gradient plate behind your name.',
    emoji: '💜',
    price: 220,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'night_owl_badge',
    name: 'Night Owl Badge',
    description: 'Show off your late-night study sessions.',
    emoji: '🦉',
    price: 180,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'crimson_name',
    name: 'Crimson Name Color',
    description: 'Make your username glow in bold crimson.',
    emoji: '🔴',
    price: 250,
    cosmeticType: _CosmeticType.nameColor,
  ),
  _ShopItem(
    seasonId: 'season_1',
    id: 'ocean_deep',
    name: 'Ocean Deep Nameplate',
    description: 'A deep teal-to-cyan plate, calm as the sea.',
    emoji: '🌊',
    price: 220,
    cosmeticType: _CosmeticType.nameplate,
  ),
];

const _season2TimedTemplates = [
  _ShopItem(
    seasonId: 'season_2',
    id: 'exam_master_card',
    name: 'Exam Master Card',
    description: 'A finals glow card with a bright animated edge.',
    emoji: '💫',
    price: 290,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    seasonId: 'season_2',
    id: 'all_nighter_badge',
    name: 'All-Nighter Badge',
    description: 'For those who always finish strong.',
    emoji: '🌃',
    price: 190,
    cosmeticType: _CosmeticType.badge,
  ),
  _ShopItem(
    seasonId: 'season_2',
    id: 'valedictorian_card',
    name: 'Valedictorian Card',
    description: 'A polished card that frames your profile name.',
    emoji: '🎓',
    price: 300,
    cosmeticType: _CosmeticType.nameplate,
  ),
  _ShopItem(
    seasonId: 'season_2',
    id: 'finals_fire_badge',
    name: 'Finals Fire Badge',
    description: 'A hot-streak badge for finals season.',
    emoji: '🔥',
    price: 210,
    cosmeticType: _CosmeticType.badge,
  ),
];

const _season1RolloverRules = [
  (
    id: 'badge_spring_sprout',
    name: 'Spring Sprout Badge',
    description: 'Season 1 pass reward now available in the shop.',
    emoji: '🌱',
    price: 260,
    cosmeticType: _CosmeticType.badge,
  ),
  (
    id: 'badge_blossom_brawler',
    name: 'Blossom Brawler Badge',
    description: 'Season 1 pass reward now available in the shop.',
    emoji: '🌸',
    price: 270,
    cosmeticType: _CosmeticType.badge,
  ),
  (
    id: 'Cherry Blossom',
    name: 'Cherry Blossom Nameplate',
    description: 'Season 1 final reward now available in the shop.',
    emoji: '🌸',
    price: 340,
    cosmeticType: _CosmeticType.nameplate,
  ),
];

List<_TimedShopItem> _buildTimedDrops(
  String seasonId,
  DateTime startsAtUtc,
  List<_ShopItem> templates,
) {
  final offsets =
      deterministicDropOffsets(seasonId: seasonId, itemCount: templates.length);
  return List.generate(templates.length, (index) {
    final item = templates[index];
    return _TimedShopItem(
      seasonId: seasonId,
      id: item.id,
      name: item.name,
      description: item.description,
      emoji: item.emoji,
      price: item.price,
      cosmeticType: item.cosmeticType,
      unlocksAt: startsAtUtc.add(Duration(days: offsets[index])),
    );
  });
}

// ── Shop body ────────────────────────────────────────────────────────────────

class _ShopBody extends StatelessWidget {
  const _ShopBody();

  void _purchase(BuildContext context, _ShopItem item) {
    final user = context.read<UserProvider>();

    final alreadyOwned = user.unlockedCosmetics.contains(item.id) ||
        user.unlockedCosmetics.contains('nameplate_${item.id}');
    if (alreadyOwned) {
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
    final timeTravelEnabled = user.shopTimeTravelEnabled;
    final nowUtc = context.watch<DevClockProvider>().nowUtc();
    final activeSeason = activeSeasonAt(nowUtc);

    final currentPermanent = activeSeason.id == kSeason2.id
      ? _season2PermanentItems
      : <_ShopItem>[];
    final currentTimed = activeSeason.id == kSeason2.id
      ? _buildTimedDrops(
        activeSeason.id,
        activeSeason.startsAtUtc,
        _season2TimedTemplates,
        )
      : <_TimedShopItem>[];
    final legacyTimed = _buildTimedDrops(
      kSeason1.id,
      kSeason1.startsAtUtc,
      _season1TimedTemplates,
    );
    final rolloverUnlockAt = shopEligibleAtForPastPassReward(
      seasonId: kSeason1.id,
    );
    final rolloverItems = _season1RolloverRules
        .map(
          (r) => _TimedShopItem(
            seasonId: kSeason1.id,
            id: r.id,
            name: r.name,
            description: r.description,
            emoji: r.emoji,
            price: r.price,
            cosmeticType: r.cosmeticType,
            unlocksAt: rolloverUnlockAt,
          ),
        )
        .toList();
    final unlockedRolloverItems = rolloverItems
        .where((item) => item.isUnlockedAt(nowUtc) || timeTravelEnabled)
        .toList();
    final lockedRolloverItems = rolloverItems
        .where((item) => !item.isUnlockedAt(nowUtc) && !timeTravelEnabled)
        .toList();
    final season1UnlockAt = shopEligibleAtForPastPassReward(
      seasonId: kSeason1.id,
    );
    final delayedSeason1Items = [
      ..._season1PermanentItems,
      ..._season1TimedTemplates,
    ]
        .map(
          (item) => _TimedShopItem(
            seasonId: item.seasonId,
            id: item.id,
            name: item.name,
            description: item.description,
            emoji: item.emoji,
            price: item.price,
            cosmeticType: item.cosmeticType,
            unlocksAt: season1UnlockAt,
          ),
        )
        .toList();
    final unlockedSeason1Items = delayedSeason1Items
        .where((item) => item.isUnlockedAt(nowUtc) || timeTravelEnabled)
        .toList();
    final lockedSeason1Items = delayedSeason1Items
        .where((item) => !item.isUnlockedAt(nowUtc) && !timeTravelEnabled)
        .toList();

    final unlockedDrops = currentTimed
        .where((i) => i.isUnlockedAt(nowUtc) || timeTravelEnabled)
        .toList();
    final lockedDrops = currentTimed
        .where((i) => !i.isUnlockedAt(nowUtc) && !timeTravelEnabled)
        .toList();
    final unlockedLegacyDrops = legacyTimed
        .where((i) =>
            i.isUnlockedAt(nowUtc) ||
            timeTravelEnabled ||
            activeSeason.id != kSeason1.id)
        .toList();

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

        if (activeSeason.id == kSeason1.id) ...[
          _SectionHeader(
            title: 'Season 1 Collection',
            subtitle:
                'All Season 1 themes and coin items unlock in 60 days with a live timer.',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          ...lockedSeason1Items.map((item) => _LockedItemCard(
                item: item,
                colorScheme: colorScheme,
              )),
          if (unlockedSeason1Items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...unlockedSeason1Items.map((item) {
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
        ] else ...[
          // ── Available Now ────────────────────────────────────────────
          _SectionHeader(
            title: 'Available Now',
            subtitle: 'Season ${activeSeason.number} featured collection',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          ...currentPermanent.map((item) {
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
        ],

        if (activeSeason.id == kSeason2.id) ...[
          const SizedBox(height: 12),
          _SectionHeader(
            title: 'Season 1 Legacy Collection',
            subtitle:
                'Missed rewards unlock in the shop after 60 days with a live timer.',
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          ..._season1PermanentItems.map((item) {
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
          ...unlockedRolloverItems.map((item) {
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
          if (lockedRolloverItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...lockedRolloverItems.map((item) => _LockedItemCard(
                  item: item,
                  colorScheme: colorScheme,
                )),
          ],
        ],

        // ── Coming Soon ────────────────────────────────────────────────
        if (lockedDrops.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Coming Soon',
            subtitle: 'Deterministic drops unlock every 5–7 days.',
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
      final nameColor = nameColorValue(item.id);
      return Text(
        'Aa',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: nameColor ?? Theme.of(context).colorScheme.primary,
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
    final now = DateTime.now().toUtc();
    final diff = widget.item.unlocksAt.toUtc().difference(now);
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
