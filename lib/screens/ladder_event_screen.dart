import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../providers/user_provider.dart';

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
          'May Event: Pencil Sharpener',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
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
            child: _WeekendRuleCard(colorScheme: colorScheme),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MilestoneTile(
                  milestone: 1,
                  title: '1000 XP · Pencil Badge',
                  subtitle: 'Unlock and auto-equip your new pencil badge.',
                  rewardEmoji: '✏️',
                  colorScheme: colorScheme,
                  event: event,
                  user: user,
                ),
                _MilestoneTile(
                  milestone: 2,
                  title: '2000 XP · Profile Frame',
                  subtitle:
                      'Unlock the yellow + black sharpener-glow profile frame.',
                  rewardEmoji: '🟨',
                  colorScheme: colorScheme,
                  event: event,
                  user: user,
                ),
                _MilestoneTile(
                  milestone: 3,
                  title: '3000 XP · Animated Nameplate',
                  subtitle:
                      'Unlock and auto-equip the animated sharpener nameplate.',
                  rewardEmoji: '⚡',
                  colorScheme: colorScheme,
                  event: event,
                  user: user,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final xp = event.totalXpDuringEvent;
    final progressToGoal = (xp / EventProvider.milestoneXp[3]).clamp(0.0, 1.0);

    String title;
    String subtitle;
    Color accent;

    switch (event.state) {
      case EventState.upcoming:
        final d = timeUntilStart;
        final days = d.inDays;
        final hours = d.inHours.remainder(24);
        final mins = d.inMinutes.remainder(60);
        title = 'Starting Soon';
        subtitle =
            '${days}d ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m until launch';
        accent = const Color(0xFFFFA000);
      case EventState.active:
        title = 'Event Live · May 3 - 15';
        subtitle = '$xp XP earned · Milestone ${event.highestReachedMilestone}/3 reached';
        accent = const Color(0xFFFFC107);
      case EventState.ended:
        final unclaimed =
            event.highestReachedMilestone - event.claimedMilestones.length;
        title = 'Event Ended';
        subtitle = unclaimed > 0
            ? '$unclaimed reward${unclaimed == 1 ? '' : 's'} still waiting to be claimed.'
            : 'Thanks for playing the May event.';
        accent = colorScheme.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFEB3B).withAlpha(38),
            const Color(0xFF212121).withAlpha(32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressToGoal,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$xp / 3000 XP',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WeekendRuleCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _WeekendRuleCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>();
    final usedToday = event.weekendBonusUsedToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Weekend bonus active: double XP with a +500 bonus XP/day cap. '
              'Today\'s bonus used: $usedToday/${EventProvider.weekendBonusDailyCap}.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final int milestone;
  final String title;
  final String subtitle;
  final String rewardEmoji;
  final ColorScheme colorScheme;
  final EventProvider event;
  final UserProvider user;

  const _MilestoneTile({
    required this.milestone,
    required this.title,
    required this.subtitle,
    required this.rewardEmoji,
    required this.colorScheme,
    required this.event,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final reached = event.isMilestoneReached(milestone);
    final claimed = event.isMilestoneClaimed(milestone);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: claimed
            ? Colors.green.withAlpha(20)
            : reached
                ? colorScheme.primaryContainer.withAlpha(55)
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claimed
              ? Colors.green.withAlpha(100)
              : reached
                  ? colorScheme.primary.withAlpha(90)
                  : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Text(rewardEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (claimed)
            Text(
              'Claimed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            )
          else if (reached)
            FilledButton(
              onPressed: () => _claim(context),
              child: const Text('Claim'),
            )
          else
            Text(
              '${EventProvider.milestoneXp[milestone]} XP',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  void _claim(BuildContext context) {
    final ok = event.claimMilestone(milestone);
    if (!ok) return;

    if (milestone == 1) {
      user.unlockCosmetic('pencil_badge');
      user.equipBadge('pencil_badge');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✏️ Pencil badge unlocked and equipped!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (milestone == 2) {
      user.unlockCosmetic('sharpener_profile_frame');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🟨 Sharpener profile frame unlocked!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    user.unlockCosmetic('animated_sharpener_nameplate');
    user.setActiveNameplate('animated_sharpener_nameplate');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Animated sharpener nameplate unlocked + equipped!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
