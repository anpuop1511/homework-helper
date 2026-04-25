import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/season_live_ops.dart';
import '../providers/dev_clock_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_cup_reveal_widget.dart';
import 'season_shop_screen.dart';

// ── Design constants ────────────────────────────────────────────────────────
const _kPink = Color(0xFFFF6B9D);
const _kOrange = Color(0xFFFFB347);
const _kGoldDark = Color(0xFFB8860B);
const _kPremiumGradient = [Color(0xFFFFD700), Color(0xFFFF8C00)];
const _kFreeGradient = [Color(0xFF64B5F6), Color(0xFF1976D2)];

String _monthDay(DateTime utc) {
  const month = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${month[utc.month]} ${utc.day}';
}

/// The Homework Battle Pass screen — Season 1: Spring Bloomin' 🌸
class BattlePassScreen extends StatelessWidget {
  const BattlePassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _BattlePassBody(),
    );
  }
}

class _BattlePassBody extends StatelessWidget {
  const _BattlePassBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final activeSeason = activeSeasonAt(
      context.watch<DevClockProvider>().nowUtc(),
    );
    final freeRewards =
        activeSeason.id == kSeason2.id ? _season2FreeRewards : _freeRewards;
    final premiumRewards = activeSeason.id == kSeason2.id
        ? _season2PremiumRewards
        : _premiumRewards;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFB347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌸', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Season ${activeSeason.number}: ${activeSeason.name}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_monthDay(activeSeason.startsAtUtc)} – ${_monthDay(activeSeason.endsAtUtc)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Coin balance pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(60), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.coins}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Season XP bar
                      _SeasonXpBar(user: user),
                    ],
                  ),
                ),
              ),
            ),
          ),
          backgroundColor: _kPink,
        ),

        // ── Track header labels ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // Free track label
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _kFreeGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '🆓  Free Track',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // tier circle space
                // Pass track label
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _kPremiumGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '⭐  Pass / 🏆 Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Pass purchase buttons ────────────────────────────────────
        SliverToBoxAdapter(
          child: _PassPurchaseSection(user: user, colorScheme: Theme.of(context).colorScheme),
        ),

        SliverToBoxAdapter(
          child: _UnclaimedRewardsSection(
            season: activeSeason,
          ),
        ),

        // ── Season Shop banner ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SeasonShopScreen()),
              ),
              icon: const Text('🛒', style: TextStyle(fontSize: 16)),
              label: const Text('Season Shop — Exclusive Cosmetics'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // ── Tier list ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tier = index + 1;
                // Milestone marker every 10 tiers
                if (tier > 1 && (tier - 1) % 10 == 0) {
                  return Column(
                    children: [
                      _MilestoneMarker(tier: tier - 1),
                        _TierRow(
                          tier: tier,
                          user: user,
                          season: activeSeason,
                          freeRewards: freeRewards,
                          premiumRewards: premiumRewards,
                          colorScheme: Theme.of(context).colorScheme,
                        ),
                    ],
                  );
                }
                return _TierRow(
                  tier: tier,
                  user: user,
                  season: activeSeason,
                  freeRewards: freeRewards,
                  premiumRewards: premiumRewards,
                  colorScheme: Theme.of(context).colorScheme,
                );
              },
              childCount: 50,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Milestone Marker ──────────────────────────────────────────────────────

class _MilestoneMarker extends StatelessWidget {
  final int tier;
  const _MilestoneMarker({required this.tier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                color: colorScheme.outlineVariant.withAlpha(120), height: 1),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tier $tier milestone! 🎉',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: Divider(
                color: colorScheme.outlineVariant.withAlpha(120), height: 1),
          ),
        ],
      ),
    );
  }
}

// ── Season XP Bar ──────────────────────────────────────────────────────────

class _SeasonXpBar extends StatelessWidget {
  final UserProvider user;
  const _SeasonXpBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final progress = user.seasonXp / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tier ${user.seasonTier} / 50',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              '${user.seasonXp} / 100 XP',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Glow overlay on the filled portion
            if (progress > 0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(60),
                          Colors.white.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Pass Purchase Section ──────────────────────────────────────────────────

class _PassPurchaseSection extends StatelessWidget {
  final UserProvider user;
  final ColorScheme colorScheme;

  const _PassPurchaseSection(
      {required this.user, required this.colorScheme});

  /// Shows a "Learn More" dialog with perks before confirming the purchase.
  void _showPassDialog(BuildContext context, String type, int price) {
    final isPlus = type == 'plus';
    final season = activeSeasonAt(
      context.read<DevClockProvider>().nowUtc(),
    );
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(isPlus ? '⭐' : '🏆', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              isPlus ? 'Pass' : 'Premium Pass',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perks included:',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (isPlus) ...[
              const _PerkRow(emoji: '✅', text: 'Access to the Pass reward track'),
              const _PerkRow(emoji: '🎁', text: 'Exclusive pass badges & nameplates'),
              const _PerkRow(emoji: '[+]', text: '[+] icon shown next to your name'),
              _PerkRow(
                emoji: season.id == kSeason2.id ? '🎓' : '🌿',
                text: season.id == kSeason2.id
                    ? 'Finals-themed cosmetics and cards'
                    : 'Spring Mint theme unlock',
              ),
            ] else ...[
              const _PerkRow(emoji: '✅', text: 'Access to the Premium reward track'),
              const _PerkRow(emoji: '🚀', text: '+3 Tiers instantly on purchase'),
              const _PerkRow(emoji: '🏆', text: 'Golden & Magical Coin Cups'),
              _PerkRow(
                emoji: '✨',
                text: season.id == kSeason2.id
                    ? 'Animated A+ Nameplate at Tier 50'
                    : 'Animated Golden Cherry Blossom Nameplate at Tier 50',
              ),
              const _PerkRow(emoji: '[★]', text: '[★] icon shown next to your name'),
              _PerkRow(
                emoji: season.id == kSeason2.id ? '🃏' : '🌼',
                text: season.id == kSeason2.id
                    ? 'Exclusive finals cards, badges, and themes'
                    : 'Daffodil & Cherry Blossom themes',
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Cost: $price 🪙',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isPlus
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                  ),
            child: Text('Purchase for $price 🪙'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      if (!context.mounted) return;
      _buyPass(context, type, price);
    });
  }

  void _buyPass(BuildContext context, String type, int price) {
    final user = context.read<UserProvider>();
    final success = user.spendCoins(price);
    if (success) {
      user.setPassType(type);
      // Premium Pass bonus: instantly grant +300 Season XP (= +3 tiers).
      if (type == 'premium') {
        user.addSeasonXp(300);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 ${type == 'plus' ? 'Plus' : 'Premium'} Pass unlocked!'
              '${type == 'premium' ? ' +3 Tiers granted!' : ''}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins! You need $price 🪙 (have ${user.coins})'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.passType == 'premium') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFFFFD700).withAlpha(120)),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                'Premium Pass Active',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB8860B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          // Current balance
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${user.coins} coins',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (user.passType == 'free') ...[
            // Pass button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPassDialog(context, 'plus', 499),
                icon: const Text('⭐', style: TextStyle(fontSize: 16)),
                label: const Text('Unlock Pass — 499 🪙'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Premium Pass button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showPassDialog(context, 'premium', 999),
              icon: const Text('🏆', style: TextStyle(fontSize: 16)),
              label: const Text('Unlock Premium Pass — 999 🪙'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single perk row shown inside the pass purchase dialog.
class _PerkRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _PerkRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Reward Type & Data ─────────────────────────────────────────────────────

enum _RewardType { coins, nameplate, xpBoost, badge, theme }

class _TierReward {
  final String label;
  final String emoji;
  final _RewardType type;
  /// Cosmetic/nameplate/vibe ID for non-coin rewards; unused for coins.
  final String value;
  /// XP amount for xpBoost rewards.
  final int xpAmount;
  /// Cup rarity for coin cup rewards.
  final CupRarity cupRarity;

  const _TierReward({
    required this.label,
    required this.emoji,
    required this.type,
    this.value = '',
    this.xpAmount = 0,
    this.cupRarity = CupRarity.rare,
  });
}

// ── Free-track reward table (index 0 = Tier 1, index 49 = Tier 50) ─────────

const _freeRewards = <_TierReward>[
  // T1
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T2
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T3
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T4
  _TierReward(label: 'Spring Sprout Badge', emoji: '🌱', type: _RewardType.badge, value: 'spring_sprout'),
  // T5
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T6
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T7
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T8
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T9
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T10
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T11
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T12
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T13
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T14
  _TierReward(label: 'Blossom Brawler Badge', emoji: '🥊', type: _RewardType.badge, value: 'blossom_brawler'),
  // T15
  _TierReward(label: 'Spring Mint Theme', emoji: '🌿', type: _RewardType.theme, value: 'springMint'),
  // T16
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T17
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T18
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T19
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T20
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T21
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T22
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T23
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T24
  _TierReward(label: 'Petal Collector Badge', emoji: '🌼', type: _RewardType.badge, value: 'petal_collector'),
  // T25
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T26
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T27
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T28
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T29
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T30
  _TierReward(label: 'Sky Bloom Theme', emoji: '🩵', type: _RewardType.theme, value: 'skyBloom'),
  // T31
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T32
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T33
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T34
  _TierReward(label: 'Bloom Scholar Badge', emoji: '📚', type: _RewardType.badge, value: 'bloom_scholar'),
  // T35
  _TierReward(label: 'Shiny Coin Cup', emoji: '✨', type: _RewardType.coins, cupRarity: CupRarity.shiny),
  // T36
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T37
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T38
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T39
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T40
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T41
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T42
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T43
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T44
  _TierReward(label: 'Blossom Warrior Badge', emoji: '⚔️', type: _RewardType.badge, value: 'blossom_warrior'),
  // T45
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  // T46
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T47
  _TierReward(label: 'Shiny Coin Cup', emoji: '✨', type: _RewardType.coins, cupRarity: CupRarity.shiny),
  // T48
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  // T49
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T50
  _TierReward(label: 'Cherry Blossom Nameplate', emoji: '🌺', type: _RewardType.nameplate, value: 'Cherry Blossom'),
];

// ── Plus/Premium-track reward table ─────────────────────────────────────────

const _premiumRewards = <_TierReward>[
  // T1
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T2
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T3
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T4
  _TierReward(label: 'Sakura Storm Badge', emoji: '🌪️', type: _RewardType.badge, value: 'sakura_storm'),
  // T5
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T6
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T7
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T8
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T9
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T10
  _TierReward(label: 'Daffodil Theme', emoji: '🌼', type: _RewardType.theme, value: 'daffodil'),
  // T11
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T12
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T13
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T14
  _TierReward(label: 'Petal Warrior Badge', emoji: '🛡️', type: _RewardType.badge, value: 'petal_warrior'),
  // T15
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T16
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T17
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T18
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T19
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T20
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T21
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T22
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T23
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T24
  _TierReward(label: 'Spring Royale Badge', emoji: '👑', type: _RewardType.badge, value: 'spring_royale'),
  // T25
  _TierReward(label: 'Cherry Blossom Theme', emoji: '🌸', type: _RewardType.theme, value: 'cherryBlossom'),
  // T26
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T27
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T28
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T29
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T30
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T31
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T32
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T33
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T34
  _TierReward(label: 'Sakura Legend Badge', emoji: '🌟', type: _RewardType.badge, value: 'sakura_legend'),
  // T35
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T36
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T37
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T38
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T39
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  // T40
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T41
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T42
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T43
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T44
  _TierReward(label: 'Grand Blossom Badge', emoji: '💮', type: _RewardType.badge, value: 'grand_blossom'),
  // T45
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T46
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T47
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  // T48
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  // T49
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  // T50
  _TierReward(label: 'Animated Golden Cherry Blossom Nameplate', emoji: '✨', type: _RewardType.nameplate, value: 'animated_golden_cherry_blossom'),
];

const _season2FreeRewards = <_TierReward>[
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Finals Focus Badge', emoji: '🎯', type: _RewardType.badge, value: 'finals_focus'),
  _TierReward(label: 'Rare Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Exam Ace Badge', emoji: '🏅', type: _RewardType.badge, value: 'exam_ace'),
  _TierReward(label: 'Finals Theme: Midnight Cram', emoji: '🌙', type: _RewardType.theme, value: 'midnightCram'),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Top of Class Badge', emoji: '🎓', type: _RewardType.badge, value: 'top_of_class'),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Finals Theme: Victory Lap', emoji: '🏁', type: _RewardType.theme, value: 'victoryLap'),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Shiny Coin Cup', emoji: '✨', type: _RewardType.coins, cupRarity: CupRarity.shiny),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: 'Coin Cup', emoji: '🥤', type: _RewardType.coins, cupRarity: CupRarity.rare),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Shiny Coin Cup', emoji: '✨', type: _RewardType.coins, cupRarity: CupRarity.shiny),
  _TierReward(label: '+50 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 50),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Finals Nameplate', emoji: '🎓', type: _RewardType.nameplate, value: 'finals_nameplate'),
];

const _season2PremiumRewards = <_TierReward>[
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Finals Glow Card', emoji: '🃏', type: _RewardType.nameplate, value: 'finals_glow_card'),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Finals Theme: Gold Notes', emoji: '📒', type: _RewardType.theme, value: 'goldNotes'),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Honor Roll Card', emoji: '🪪', type: _RewardType.nameplate, value: 'honor_roll_card'),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Epic Coin Cup', emoji: '🧪', type: _RewardType.coins, cupRarity: CupRarity.epic),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Magical Coin Cup', emoji: '🔮', type: _RewardType.coins, cupRarity: CupRarity.magical),
  _TierReward(label: '+100 XP Boost', emoji: '⚡', type: _RewardType.xpBoost, xpAmount: 100),
  _TierReward(label: 'Golden Coin Cup', emoji: '🏆', type: _RewardType.coins, cupRarity: CupRarity.golden),
  _TierReward(label: 'Animated A+ Nameplate', emoji: '✨', type: _RewardType.nameplate, value: 'animated_aplus_nameplate'),
];

List<_TierReward> _freeRewardsForSeason(String seasonId) {
  return seasonId == kSeason2.id ? _season2FreeRewards : _freeRewards;
}

List<_TierReward> _premiumRewardsForSeason(String seasonId) {
  return seasonId == kSeason2.id ? _season2PremiumRewards : _premiumRewards;
}

class _UnclaimedRewardsSection extends StatelessWidget {
  final SeasonDefinition season;

  const _UnclaimedRewardsSection({
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    if (season.number <= 1) return const SizedBox.shrink();
    final user = context.watch<UserProvider>();
    final items = <_PastRewardClaim>[];
    for (final s in kAllSeasons) {
      if (s.id == season.id || s.startsAtUtc.isAfter(season.startsAtUtc)) {
        continue;
      }
      final reached = user.tierForSeason(s.id);
      if (reached <= 0) continue;
      final free = _freeRewardsForSeason(s.id);
      final premium = _premiumRewardsForSeason(s.id);
      for (var tier = 1; tier <= reached && tier <= 50; tier++) {
        if (!user.isTierRewardClaimed(tier, side: 'free', seasonId: s.id)) {
          items.add(
            _PastRewardClaim(
              season: s,
              tier: tier,
              side: 'free',
              reward: free[tier - 1],
              locked: false,
            ),
          );
        }
        final needs = tier == 50 ? 'premium' : 'plus';
        final hasEntitlement = passMeetsRequirement(
          user.passTypeForSeason(s.id),
          needs,
        );
        if (hasEntitlement &&
            !user.isTierRewardClaimed(tier, side: 'premium', seasonId: s.id)) {
          items.add(
            _PastRewardClaim(
              season: s,
              tier: tier,
              side: 'premium',
              reward: premium[tier - 1],
              locked: !hasEntitlement,
            ),
          );
        }
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();
    final displayItems = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unclaimed Rewards',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Claim eligible rewards from previous seasons.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ...displayItems.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(item.reward.emoji),
                title: Text(
                  'S${item.season.number} T${item.tier} • ${item.reward.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.side == 'free' ? 'Free' : 'Pass track'),
                trailing: TextButton(
                  onPressed: () => item.locked
                      ? _showLocked(context, item.season)
                      : _claim(context, item),
                  child: Text(item.locked ? 'Locked' : 'Claim'),
                ),
              ),
            ),
            if (items.length > displayItems.length)
              Text(
                '+${items.length - displayItems.length} more rewards available',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLocked(BuildContext context, SeasonDefinition season) {
    final availableAt = shopEligibleAtForPastPassReward(seasonId: season.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Locked Cosmetic'),
        content: Text(
          'This cosmetic was for Season ${season.number} Battle Pass holders.\n'
          'It will be available after 60 days when the season ends.\n'
          'Available on ${_monthDay(availableAt)} ${availableAt.year} (UTC).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _claim(BuildContext context, _PastRewardClaim item) {
    final user = context.read<UserProvider>();
    final reward = item.reward;
    switch (reward.type) {
      case _RewardType.coins:
        showCoinCupReveal(
          context,
          initialRarity: reward.cupRarity,
          onClaimed: (coins) {
            user.awardCoins(coins);
            user.claimTierReward(
              item.tier,
              side: item.side,
              seasonId: item.season.id,
            );
          },
        );
      case _RewardType.nameplate:
        user.setActiveNameplate(reward.value);
        user.unlockCosmetic('nameplate_${reward.value}');
        user.claimTierReward(item.tier, side: item.side, seasonId: item.season.id);
      case _RewardType.xpBoost:
        user.awardXp(reward.xpAmount);
        user.claimTierReward(item.tier, side: item.side, seasonId: item.season.id);
      case _RewardType.badge:
        user.unlockCosmetic('badge_${reward.value}');
        user.claimTierReward(item.tier, side: item.side, seasonId: item.season.id);
      case _RewardType.theme:
        user.unlockCosmetic('vibe_${reward.value}');
        user.claimTierReward(item.tier, side: item.side, seasonId: item.season.id);
    }
  }
}

class _PastRewardClaim {
  final SeasonDefinition season;
  final int tier;
  final String side;
  final _TierReward reward;
  final bool locked;

  const _PastRewardClaim({
    required this.season,
    required this.tier,
    required this.side,
    required this.reward,
    required this.locked,
  });
}

// ── Tier Row ───────────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final int tier;
  final UserProvider user;
  final SeasonDefinition season;
  final List<_TierReward> freeRewards;
  final List<_TierReward> premiumRewards;
  final ColorScheme colorScheme;

  const _TierRow({
    required this.tier,
    required this.user,
    required this.season,
    required this.freeRewards,
    required this.premiumRewards,
    required this.colorScheme,
  });

  bool get _isReached => user.tierForSeason(season.id) >= tier;
  bool get _isFreeClaimed =>
      user.isTierRewardClaimed(tier, side: 'free', seasonId: season.id);
  bool get _isPremiumClaimed =>
      user.isTierRewardClaimed(tier, side: 'premium', seasonId: season.id);
  bool get _isCurrent =>
      season.id == user.activeSeasonId && user.seasonTier == tier;

  _TierReward get _freeReward => freeRewards[tier - 1];
  _TierReward get _premiumReward => premiumRewards[tier - 1];

  @override
  Widget build(BuildContext context) {
    final isTier50 = tier == 50;
    final isMilestone = tier % 10 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: _isReached && !_isCurrent
            ? LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withAlpha(60),
                  colorScheme.surfaceContainerLow,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: _isCurrent
            ? null
            : (_isReached ? null : colorScheme.surfaceContainerLow),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isCurrent
              ? colorScheme.primary
              : isMilestone
                  ? _kOrange.withAlpha(120)
                  : colorScheme.outlineVariant.withAlpha(60),
          width: _isCurrent ? 2 : (isMilestone ? 1.5 : 0.8),
        ),
        boxShadow: _isCurrent
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: _isCurrent
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withAlpha(100),
                    colorScheme.primaryContainer.withAlpha(40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: _rowContent(context, isTier50),
            )
          : _rowContent(context, isTier50),
    );
  }

  Widget _rowContent(BuildContext context, bool isTier50) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          // Left: free reward
          Expanded(
            child: _RewardCell(
              reward: _freeReward,
              isReached: _isReached,
              isClaimed: _isFreeClaimed,
              passRequired: 'free',
              userPassType: user.passType,
              onClaim: () => _claimFree(context),
              colorScheme: colorScheme,
              isTier50: isTier50,
            ),
          ),

          // Middle: tier number
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isReached
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFFB347)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _isReached ? null : colorScheme.surfaceContainerHigh,
              boxShadow: _isReached
                  ? [
                      BoxShadow(
                        color: _kPink.withAlpha(60),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$tier',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _isReached
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Right: plus/premium reward
          Expanded(
            child: _RewardCell(
              reward: _premiumReward,
              isReached: _isReached,
              isClaimed: _isPremiumClaimed,
              passRequired: isTier50 ? 'premium' : 'plus',
              userPassType: user.passType,
              onClaim: () => _claimPremium(context),
              colorScheme: colorScheme,
              isTier50: isTier50,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }

  void _claimFree(BuildContext context) {
    final user = context.read<UserProvider>();
    final reward = _freeReward;
    switch (reward.type) {
      case _RewardType.coins:
        showCoinCupReveal(
          context,
          initialRarity: reward.cupRarity,
          onClaimed: (coins) {
            user.awardCoins(coins);
            user.claimTierReward(tier, side: 'free', seasonId: season.id);
          },
        );
      case _RewardType.nameplate:
        user.setActiveNameplate(reward.value);
        user.unlockCosmetic('nameplate_${reward.value}');
        user.claimTierReward(tier, side: 'free', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🌸 ${reward.label} equipped!')),
        );
      case _RewardType.xpBoost:
        user.awardXp(reward.xpAmount);
        user.claimTierReward(tier, side: 'free', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚡ ${reward.label} applied! +${reward.xpAmount} XP')),
        );
      case _RewardType.badge:
        user.unlockCosmetic('badge_${reward.value}');
        user.claimTierReward(tier, side: 'free', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} unlocked!')),
        );
      case _RewardType.theme:
        user.unlockCosmetic('vibe_${reward.value}');
        user.claimTierReward(tier, side: 'free', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} theme unlocked! Find it in Settings → Appearance.')),
        );
    }
  }

  void _claimPremium(BuildContext context) {
    final user = context.read<UserProvider>();
    final hasAccess = passMeetsRequirement(
      user.passTypeForSeason(season.id),
      tier == 50 ? 'premium' : 'plus',
    );
    if (!hasAccess) {
      _showPastPassLockedDialog(context);
      return;
    }
    if (tier == 50 && user.passTypeForSeason(season.id) != 'premium') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Premium Pass required for the Animated Golden Nameplate!')),
      );
      return;
    }
    final reward = _premiumReward;
    switch (reward.type) {
      case _RewardType.coins:
        showCoinCupReveal(
          context,
          initialRarity: reward.cupRarity,
          onClaimed: (coins) {
            user.awardCoins(coins);
            user.claimTierReward(tier, side: 'premium', seasonId: season.id);
          },
        );
      case _RewardType.nameplate:
        user.setActiveNameplate(reward.value);
        user.unlockCosmetic('nameplate_${reward.value}');
        user.claimTierReward(tier, side: 'premium', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✨ ${reward.label} equipped!')),
        );
      case _RewardType.xpBoost:
        user.awardXp(reward.xpAmount);
        user.claimTierReward(tier, side: 'premium', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚡ ${reward.label} applied! +${reward.xpAmount} XP')),
        );
      case _RewardType.badge:
        user.unlockCosmetic('badge_${reward.value}');
        user.claimTierReward(tier, side: 'premium', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} unlocked!')),
        );
      case _RewardType.theme:
        user.unlockCosmetic('vibe_${reward.value}');
        user.claimTierReward(tier, side: 'premium', seasonId: season.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} theme unlocked! Find it in Settings → Appearance.')),
        );
    }
  }

  void _showPastPassLockedDialog(BuildContext context) {
    final availableAt = shopEligibleAtForPastPassReward(seasonId: season.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Locked Cosmetic'),
        content: Text(
          'This cosmetic was for Season ${season.number} Battle Pass holders.\n'
          'It will be available after 60 days when the season ends.\n'
          'Available on ${_monthDay(availableAt)} ${availableAt.year} (UTC).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Reward Cell ────────────────────────────────────────────────────────────

class _RewardCell extends StatelessWidget {
  final _TierReward reward;
  final bool isReached;
  final bool isClaimed;
  final String passRequired;
  final String userPassType;
  final VoidCallback onClaim;
  final ColorScheme colorScheme;
  final bool isTier50;
  final bool alignRight;

  const _RewardCell({
    required this.reward,
    required this.isReached,
    required this.isClaimed,
    required this.passRequired,
    required this.userPassType,
    required this.onClaim,
    required this.colorScheme,
    this.isTier50 = false,
    this.alignRight = false,
  });

  bool get _hasAccess {
    if (passRequired == 'free') return true;
    if (passRequired == 'premium') return userPassType == 'premium';
    return userPassType == 'plus' || userPassType == 'premium';
  }

  bool get _canClaim => isReached && !isClaimed && _hasAccess;

  Color get _trackColor =>
      passRequired == 'free' ? const Color(0xFF1976D2) : _kOrange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Emoji in a small pill
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isReached
                    ? _trackColor.withAlpha(28)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Text(reward.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                reward.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isReached
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withAlpha(140),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (!_hasAccess) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_rounded,
                  size: 12, color: colorScheme.onSurfaceVariant.withAlpha(140)),
            ],
          ],
        ),
        if (_canClaim) ...[
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onClaim,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: passRequired == 'free'
                      ? _kFreeGradient
                      : _kPremiumGradient,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _trackColor.withAlpha(60),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Claim',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ] else if (isClaimed) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✓ Claimed',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else if (!_hasAccess && isReached) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kOrange.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              passRequired == 'premium' ? '🏆 Premium' : '⭐ Plus+',
              style: TextStyle(
                fontSize: 9,
                color: _kGoldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
