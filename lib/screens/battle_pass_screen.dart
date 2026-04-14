import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_cup_reveal_widget.dart';

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

  void _buyPass(BuildContext context, String type, int price) {
    final user = context.read<UserProvider>();
    final success = user.spendCoins(price);
    if (success) {
      user.setPassType(type);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 ${type == 'plus' ? 'Plus' : 'Premium'} Pass unlocked!'),
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
                onPressed: () => _buyPass(context, 'plus', 499),
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
              onPressed: () => _buyPass(context, 'premium', 999),
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
  bool get _isClaimed => user.claimedTiers.contains(tier);
  bool get _isCurrent => user.seasonTier == tier;

  // Free reward for each tier
  _TierReward get _freeReward {
    if (tier == 50) {
      return const _TierReward(
        label: 'Cherry Blossom Nameplate',
        emoji: '🌸',
        type: _RewardType.nameplate,
        value: 'Cherry Blossom',
        coins: 0,
      );
    }
    final coins = (tier % 5 == 0) ? 30 : 20;
    return _TierReward(
      label: '$coins Coins',
      emoji: '🪙',
      type: _RewardType.coins,
      value: '',
      coins: coins,
    );
  }

  // Plus/Premium reward for each tier
  _TierReward get _premiumReward {
    if (tier == 50) {
      return const _TierReward(
        label: 'Animated Golden Cherry Blossom Nameplate',
        emoji: '✨',
        type: _RewardType.nameplate,
        value: 'animated_golden_cherry_blossom',
        coins: 0,
      );
    }
    final coins = (tier % 10 == 0) ? 100 : 50;
    return _TierReward(
      label: '$coins Coins',
      emoji: '🪙',
      type: _RewardType.coins,
      value: '',
      coins: coins,
    );
  }

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
                isClaimed: _isClaimed,
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
                isClaimed: _isClaimed,
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
    if (reward.type == _RewardType.coins) {
      showCoinCupReveal(
        context,
        initialRarity: tier % 10 == 0
            ? CupRarity.epic
            : (tier % 5 == 0 ? CupRarity.rare : CupRarity.rare),
        onClaimed: (coins) {
          user.awardCoins(coins);
          user.claimTierReward(tier);
        },
      );
    } else if (reward.type == _RewardType.nameplate) {
      user.setActiveNameplate(reward.value);
      user.unlockCosmetic('nameplate_${reward.value}');
      user.claimTierReward(tier);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🌸 ${reward.label} equipped!')),
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
    if (reward.type == _RewardType.coins) {
      showCoinCupReveal(
        context,
        initialRarity: tier % 10 == 0 ? CupRarity.epic : CupRarity.rare,
        onClaimed: (coins) {
          user.awardCoins(coins);
          user.claimTierReward(tier);
        },
      );
    } else if (reward.type == _RewardType.nameplate) {
      user.setActiveNameplate(reward.value);
      user.unlockCosmetic('nameplate_${reward.value}');
      user.claimTierReward(tier);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ ${reward.label} equipped!')),
      );
    }
  }
}

// ── Reward Cell ────────────────────────────────────────────────────────────

enum _RewardType { coins, nameplate }

class _TierReward {
  final String label;
  final String emoji;
  final _RewardType type;
  final String value;
  final int coins;

  const _TierReward({
    required this.label,
    required this.emoji,
    required this.type,
    required this.value,
    required this.coins,
  });
}

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
