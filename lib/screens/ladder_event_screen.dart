import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/coin_cup_reveal_widget.dart';

// ── Reward definition ────────────────────────────────────────────────────────

enum _RewardKind { coins, seasonXp, coinCup, coinCupDouble, nameplate }

class _Reward {
  final _RewardKind kind;
  final int value; // coins or XP amount (0 for cosmetic rewards)
  final CupRarity? cupRarity; // for coinCup / coinCupDouble
  final String label;
  final String emoji;
  final String? cosmeticId; // for nameplate rewards

  const _Reward({
    required this.kind,
    required this.label,
    required this.emoji,
    this.value = 0,
    this.cupRarity,
    this.cosmeticId,
  });
}

/// Reward table for the 20-tier ladder event.
const _rewards = <_Reward>[
  _Reward(kind: _RewardKind.coinCup, label: 'Rare Coin Cup', emoji: '🥤', cupRarity: CupRarity.rare), // T1
  _Reward(kind: _RewardKind.coins, label: '10 Coins', emoji: '🪙', value: 10), // T2
  _Reward(kind: _RewardKind.coins, label: '5 Coins', emoji: '🪙', value: 5), // T3
  _Reward(kind: _RewardKind.coins, label: '10 Coins', emoji: '🪙', value: 10), // T4
  _Reward(kind: _RewardKind.seasonXp, label: '50 Season XP', emoji: '⚡', value: 50), // T5
  _Reward(kind: _RewardKind.coins, label: '15 Coins', emoji: '🪙', value: 15), // T6
  _Reward(kind: _RewardKind.coins, label: '15 Coins', emoji: '🪙', value: 15), // T7
  _Reward(kind: _RewardKind.coins, label: '15 Coins', emoji: '🪙', value: 15), // T8
  _Reward(kind: _RewardKind.coins, label: '10 Coins', emoji: '🪙', value: 10), // T9
  _Reward(kind: _RewardKind.coins, label: '25 Coins', emoji: '🪙', value: 25), // T10
  _Reward(kind: _RewardKind.seasonXp, label: '100 Season XP', emoji: '⚡', value: 100), // T11
  _Reward(kind: _RewardKind.coins, label: '10 Coins', emoji: '🪙', value: 10), // T12
  _Reward(kind: _RewardKind.coinCup, label: 'Epic Coin Cup', emoji: '🧪', cupRarity: CupRarity.epic), // T13
  _Reward(kind: _RewardKind.coins, label: '15 Coins', emoji: '🪙', value: 15), // T14
  _Reward(kind: _RewardKind.coins, label: '10 Coins', emoji: '🪙', value: 10), // T15
  _Reward(kind: _RewardKind.coinCup, label: 'Magical Coin Cup', emoji: '🔮', cupRarity: CupRarity.magical), // T16
  _Reward(kind: _RewardKind.coins, label: '15 Coins', emoji: '🪙', value: 15), // T17
  _Reward(kind: _RewardKind.coinCupDouble, label: '2× Rare Coin Cups', emoji: '🥤🥤', cupRarity: CupRarity.rare), // T18
  _Reward(kind: _RewardKind.coinCup, label: 'Shiny Coin Cup', emoji: '✨', cupRarity: CupRarity.shiny), // T19
  _Reward(kind: _RewardKind.nameplate, label: 'Notepad Nameplate', emoji: '📝', cosmeticId: 'notepad_nameplate'), // T20
];

// ── Screen ───────────────────────────────────────────────────────────────────

/// The "Complete Assignments Ladder" limited-time event screen.
class LadderEventScreen extends StatefulWidget {
  const LadderEventScreen({super.key});

  @override
  State<LadderEventScreen> createState() => _LadderEventScreenState();
}

class _LadderEventScreenState extends State<LadderEventScreen> {
  Timer? _countdownTimer;
  Duration _timeUntilStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    final event = context.read<EventProvider>();
    setState(() => _timeUntilStart = event.timeUntilStart);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final event = context.watch<EventProvider>();
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Assignments Ladder 🏆',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B35).withAlpha(30),
                const Color(0xFFFFD700).withAlpha(20),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _EventHeader(
              event: event,
              timeUntilStart: _timeUntilStart,
              colorScheme: colorScheme,
            ),
          ),
          SliverToBoxAdapter(
            child: _CoinSummaryBanner(colorScheme: colorScheme),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tier = index + 1;
                  return _TierRow(
                    tier: tier,
                    reward: _rewards[index],
                    event: event,
                    user: user,
                    colorScheme: colorScheme,
                  );
                },
                childCount: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event header ─────────────────────────────────────────────────────────────

class _EventHeader extends StatelessWidget {
  final EventProvider event;
  final Duration timeUntilStart;
  final ColorScheme colorScheme;

  const _EventHeader({
    required this.event,
    required this.timeUntilStart,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (event.state) {
      case EventState.upcoming:
        return _buildUpcoming(context);
      case EventState.active:
        return _buildActive(context);
      case EventState.ended:
        return _buildEnded(context);
    }
  }

  Widget _buildUpcoming(BuildContext context) {
    final d = timeUntilStart;
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final mins = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    final countdownText =
        '${days}d ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withAlpha(25),
            const Color(0xFFFFD700).withAlpha(18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withAlpha(80),
        ),
      ),
      child: Column(
        children: [
          Text(
            '⏳ Starting Soon',
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete assignments to climb the ladder and earn\ncoins, XP, coin cups, and the exclusive Notepad Nameplate!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              countdownText,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apr 20 – Apr 24, 2026',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActive(BuildContext context) {
    final reached = event.highestReachedTier;
    final working = event.currentWorkingTier;
    final progress = event.progressInCurrentTier;
    final goal = event.goalOfCurrentTier;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withAlpha(25),
            const Color(0xFFFFD700).withAlpha(18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Event Live! · Apr 20 – 24',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'Completed',
                value: '${event.totalCompletedDuringEvent}',
                emoji: '✅',
                colorScheme: colorScheme,
              ),
              _StatChip(
                label: 'Tiers Reached',
                value: '$reached / 20',
                emoji: '🏅',
                colorScheme: colorScheme,
              ),
            ],
          ),
          if (reached < 20) ...[
            const SizedBox(height: 14),
            Text(
              'Tier $working progress',
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal > 0 ? progress / goal : 1.0,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progress / $goal assignments',
              style: TextStyle(
                  fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              '🎉 All 20 tiers reached!',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnded(BuildContext context) {
    final reached = event.highestReachedTier;
    final claimedCount = event.claimedTiers.length;
    final unclaimedReachable = reached - claimedCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '🏁 Event Ended',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The event has ended. You reached $reached / 20 tiers.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          if (unclaimedReachable > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🎁 You still have $unclaimedReachable unclaimed reward${unclaimedReachable != 1 ? 's' : ''}!',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final ColorScheme colorScheme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.emoji,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Coin summary banner ───────────────────────────────────────────────────────

class _CoinSummaryBanner extends StatelessWidget {
  final ColorScheme colorScheme;

  const _CoinSummaryBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withAlpha(40),
            colorScheme.primaryContainer.withAlpha(120),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFFD700).withAlpha(100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'Earn up to ${EventProvider.totalDirectCoins} coins + bonus coin cups & more!',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier row ──────────────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final int tier;
  final _Reward reward;
  final EventProvider event;
  final UserProvider user;
  final ColorScheme colorScheme;

  const _TierRow({
    required this.tier,
    required this.reward,
    required this.event,
    required this.user,
    required this.colorScheme,
  });

  bool get _isReached => event.isTierReached(tier);
  bool get _isClaimed => event.isTierClaimed(tier);

  int get _tierGoal => EventProvider.tierGoals[tier];

  /// Progress indicator: completions accumulated toward this specific tier.
  int get _progressForTier {
    final cumPrev = EventProvider.cumulativeGoals[tier - 1];
    final cumThis = EventProvider.cumulativeGoals[tier];
    return (event.totalCompletedDuringEvent - cumPrev).clamp(0, cumThis - cumPrev);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = event.state != EventState.upcoming;
    final canClaim = _isReached && !_isClaimed;

    // Visual state colours
    Color borderColor;
    Color bgColor;
    if (_isClaimed) {
      bgColor = Colors.green.withAlpha(18);
      borderColor = Colors.green.withAlpha(80);
    } else if (_isReached) {
      bgColor = colorScheme.primaryContainer.withAlpha(60);
      borderColor = colorScheme.primary.withAlpha(120);
    } else {
      bgColor = colorScheme.surfaceContainerHighest.withAlpha(80);
      borderColor = colorScheme.outlineVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Tier badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isClaimed
                  ? Colors.green
                  : _isReached
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
            ),
            child: _isClaimed
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$tier',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _isReached
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Goal + reward
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reward.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reward.label,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isActive && !_isReached && tier == event.currentWorkingTier) ...[
                  // Show fine-grained progress only on the working tier
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _tierGoal > 0
                          ? _progressForTier / _tierGoal
                          : 1.0,
                      minHeight: 6,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_progressForTier / $_tierGoal assignments',
                    style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ] else ...[
                  Text(
                    '$_tierGoal assignment${_tierGoal != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          // Claim button or status
          if (_isClaimed)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Claimed ✓',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            )
          else if (canClaim)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton(
                onPressed: () => _handleClaim(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(70, 34),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Claim',
                  style: GoogleFonts.lexend(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else if (!isActive && !_isReached)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '🔒',
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }

  void _handleClaim(BuildContext context) {
    final claimed = event.claimTier(tier);
    if (!claimed) return;

    switch (reward.kind) {
      case _RewardKind.coins:
        user.awardCoins(reward.value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reward.emoji} +${reward.value} Coins!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      case _RewardKind.seasonXp:
        user.addSeasonXp(reward.value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reward.emoji} +${reward.value} Season XP!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      case _RewardKind.coinCup:
        showCoinCupReveal(
          context,
          initialRarity: reward.cupRarity!,
          onClaimed: (coins) {
            user.awardCoins(coins);
          },
        );

      case _RewardKind.coinCupDouble:
        // First cup
        showCoinCupReveal(
          context,
          initialRarity: reward.cupRarity!,
          onClaimed: (coins) {
            user.awardCoins(coins);
            // Show second cup after a brief delay.
            Future.delayed(const Duration(milliseconds: 400), () {
              if (context.mounted) {
                showCoinCupReveal(
                  context,
                  initialRarity: reward.cupRarity!,
                  onClaimed: (c2) => user.awardCoins(c2),
                );
              }
            });
          },
        );

      case _RewardKind.nameplate:
        final id = reward.cosmeticId!;
        user.unlockCosmetic(id);
        user.setActiveNameplate(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reward.emoji} ${reward.label} unlocked & equipped!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
