import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_cup_reveal_widget.dart';
import 'season_shop_screen.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>();

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B9D),
                    const Color(0xFFFFB347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Season 1: Spring Bloomin' 🌸",
                        style: GoogleFonts.lexend(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'April 13 – May 1',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Season XP bar
                      _SeasonXpBar(user: user),
                    ],
                  ),
                ),
              ),
            ),
          ),
          backgroundColor: const Color(0xFFFF6B9D),
        ),

        // ── Pass purchase buttons ────────────────────────────────────
        SliverToBoxAdapter(
          child: _PassPurchaseSection(user: user, colorScheme: colorScheme),
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
                return _TierRow(
                  tier: tier,
                  user: user,
                  colorScheme: colorScheme,
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
            Text(
              'Tier ${user.seasonTier} / 50',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '${user.seasonXp} / 100 season XP',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
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
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(isPlus ? '⭐' : '🏆', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              isPlus ? 'Plus Pass' : 'Premium Pass',
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
              const _PerkRow(emoji: '✅', text: 'Access to the Plus reward track'),
              const _PerkRow(emoji: '🎁', text: 'Exclusive Plus badges & nameplates'),
              const _PerkRow(emoji: '[+]', text: '[+] icon shown next to your name'),
              const _PerkRow(emoji: '🌿', text: 'Spring Mint theme unlock'),
            ] else ...[
              const _PerkRow(emoji: '✅', text: 'Access to the Premium reward track'),
              const _PerkRow(emoji: '🚀', text: '+3 Tiers instantly on purchase'),
              const _PerkRow(emoji: '🏆', text: 'Golden & Magical Coin Cups'),
              const _PerkRow(emoji: '✨', text: 'Animated Golden Cherry Blossom Nameplate at Tier 50'),
              const _PerkRow(emoji: '[★]', text: '[★] icon shown next to your name'),
              const _PerkRow(emoji: '🌼', text: 'Daffodil & Cherry Blossom themes'),
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
            // Plus Pass button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPassDialog(context, 'plus', 499),
                icon: const Text('⭐', style: TextStyle(fontSize: 16)),
                label: const Text('Unlock Plus Pass — 499 🪙'),
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
  _TierReward(label: 'Blossom Brawler Badge', emoji: '🌸', type: _RewardType.badge, value: 'blossom_brawler'),
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
  _TierReward(label: 'Cherry Blossom Nameplate', emoji: '🌸', type: _RewardType.nameplate, value: 'Cherry Blossom'),
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
  _TierReward(label: 'Sakura Storm Badge', emoji: '🌺', type: _RewardType.badge, value: 'sakura_storm'),
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
  _TierReward(label: 'Petal Warrior Badge', emoji: '🌺', type: _RewardType.badge, value: 'petal_warrior'),
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
  _TierReward(label: 'Grand Blossom Badge', emoji: '🌺', type: _RewardType.badge, value: 'grand_blossom'),
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

// ── Tier Row ───────────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final int tier;
  final UserProvider user;
  final ColorScheme colorScheme;

  const _TierRow({
    required this.tier,
    required this.user,
    required this.colorScheme,
  });

  bool get _isReached => user.seasonTier >= tier;
  bool get _isFreeClaimed => user.isTierRewardClaimed(tier, side: 'free');
  bool get _isPremiumClaimed => user.isTierRewardClaimed(tier, side: 'premium');
  bool get _isCurrent => user.seasonTier == tier;

  _TierReward get _freeReward => _freeRewards[tier - 1];
  _TierReward get _premiumReward => _premiumRewards[tier - 1];

  @override
  Widget build(BuildContext context) {
    final isTier50 = tier == 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isCurrent
            ? colorScheme.primaryContainer.withAlpha(80)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCurrent
              ? colorScheme.primary
              : colorScheme.outlineVariant.withAlpha(80),
          width: _isCurrent ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isReached
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHigh,
              ),
              child: Center(
                child: Text(
                  '$tier',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _isReached
                        ? colorScheme.onPrimary
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
            user.claimTierReward(tier, side: 'free');
          },
        );
      case _RewardType.nameplate:
        user.setActiveNameplate(reward.value);
        user.unlockCosmetic('nameplate_${reward.value}');
        user.claimTierReward(tier, side: 'free');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🌸 ${reward.label} equipped!')),
        );
      case _RewardType.xpBoost:
        user.awardXp(reward.xpAmount);
        user.claimTierReward(tier, side: 'free');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚡ ${reward.label} applied! +${reward.xpAmount} XP')),
        );
      case _RewardType.badge:
        user.unlockCosmetic('badge_${reward.value}');
        user.claimTierReward(tier, side: 'free');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} unlocked!')),
        );
      case _RewardType.theme:
        user.unlockCosmetic('vibe_${reward.value}');
        user.claimTierReward(tier, side: 'free');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} theme unlocked! Find it in Settings → Appearance.')),
        );
    }
  }

  void _claimPremium(BuildContext context) {
    final user = context.read<UserProvider>();
    final hasAccess = user.passType == 'plus' || user.passType == 'premium';
    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unlock Plus or Premium Pass to claim this reward!')),
      );
      return;
    }
    if (tier == 50 && user.passType != 'premium') {
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
            user.claimTierReward(tier, side: 'premium');
          },
        );
      case _RewardType.nameplate:
        user.setActiveNameplate(reward.value);
        user.unlockCosmetic('nameplate_${reward.value}');
        user.claimTierReward(tier, side: 'premium');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✨ ${reward.label} equipped!')),
        );
      case _RewardType.xpBoost:
        user.awardXp(reward.xpAmount);
        user.claimTierReward(tier, side: 'premium');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚡ ${reward.label} applied! +${reward.xpAmount} XP')),
        );
      case _RewardType.badge:
        user.unlockCosmetic('badge_${reward.value}');
        user.claimTierReward(tier, side: 'premium');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} unlocked!')),
        );
      case _RewardType.theme:
        user.unlockCosmetic('vibe_${reward.value}');
        user.claimTierReward(tier, side: 'premium');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reward.emoji} ${reward.label} theme unlocked! Find it in Settings → Appearance.')),
        );
    }
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
            Text(reward.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                reward.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isReached
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (!_hasAccess) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_rounded,
                  size: 12, color: colorScheme.onSurfaceVariant),
            ],
          ],
        ),
        if (_canClaim) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onClaim,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Claim',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ] else if (isClaimed) ...[
          const SizedBox(height: 4),
          Text(
            '✓ Claimed',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (!_hasAccess && isReached) ...[
          const SizedBox(height: 4),
          Text(
            passRequired == 'premium' ? 'Premium only' : 'Plus/Premium',
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
