import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CupRarity { rare, epic, shiny, magical, golden }

extension CupRarityExt on CupRarity {
  String get label {
    switch (this) {
      case CupRarity.rare:
        return 'Rare';
      case CupRarity.epic:
        return 'Epic';
      case CupRarity.shiny:
        return 'Shiny';
      case CupRarity.magical:
        return 'Magical';
      case CupRarity.golden:
        return 'Golden';
    }
  }

  Color get color {
    switch (this) {
      case CupRarity.rare:
        return const Color(0xFF78909C);
      case CupRarity.epic:
        return const Color(0xFF7E57C2);
      case CupRarity.shiny:
        return const Color(0xFF26C6DA);
      case CupRarity.magical:
        return const Color(0xFFEC407A);
      case CupRarity.golden:
        return const Color(0xFFFFD700);
    }
  }

  String get emoji {
    switch (this) {
      case CupRarity.rare:
        return '🥤';
      case CupRarity.epic:
        return '🧪';
      case CupRarity.shiny:
        return '✨';
      case CupRarity.magical:
        return '🔮';
      case CupRarity.golden:
        return '🏆';
    }
  }

  int get coinReward {
    switch (this) {
      case CupRarity.rare:
        return 20;
      case CupRarity.epic:
        return 35;
      case CupRarity.shiny:
        return 55;
      case CupRarity.magical:
        return 80;
      case CupRarity.golden:
        return 120;
    }
  }
}

/// A widget that displays a coin cup that can be tapped to upgrade through
/// rarities (Rare → Epic → Shiny → Magical → Golden).
/// When claimed, [onClaimed] is called with the coin reward amount.
/// [maxTaps] limits how many upgrade attempts the user gets before the cup
/// locks and must be claimed at its current rarity.
class CoinCupRevealWidget extends StatefulWidget {
  final CupRarity initialRarity;
  final void Function(int coins) onClaimed;
  final int maxTaps;

  const CoinCupRevealWidget({
    super.key,
    this.initialRarity = CupRarity.rare,
    required this.onClaimed,
    this.maxTaps = 5,
  });

  @override
  State<CoinCupRevealWidget> createState() => _CoinCupRevealWidgetState();
}

class _CoinCupRevealWidgetState extends State<CoinCupRevealWidget>
    with SingleTickerProviderStateMixin {
  late CupRarity _current;
  bool _claimed = false;
  bool _animating = false;
  int _tapsUsed = 0;
  final _random = Random();

  // Nerfed upgrade probabilities: rare→epic, epic→shiny, shiny→magical, magical→golden
  static const _upgradeChances = [0.45, 0.30, 0.20, 0.10];

  bool get _tapsExhausted => _tapsUsed >= widget.maxTaps;
  int get _tapsRemaining => widget.maxTaps - _tapsUsed;

  @override
  void initState() {
    super.initState();
    _current = widget.initialRarity;
  }

  void _onTap() {
    if (_claimed || _animating || _tapsExhausted) return;

    if (_current == CupRarity.golden) {
      _claim();
      return;
    }

    final idx = _current.index;
    final upgraded = _random.nextDouble() < _upgradeChances[idx];

    setState(() {
      _tapsUsed++;
      _animating = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        if (upgraded) {
          _current = CupRarity.values[idx + 1];
        }
        _animating = false;
      });
    });
  }

  void _claim() {
    if (_claimed) return;
    setState(() => _claimed = true);
    widget.onClaimed(_current.coinReward);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canUpgrade = !_claimed && !_tapsExhausted && _current != CupRarity.golden;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (_claimed || _tapsExhausted) ? null : _onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _current.color.withAlpha(30),
              border: Border.all(color: _current.color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _current.color.withAlpha(80),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: _animating
                  ? Pulse(
                      animate: true,
                      child: Text(
                        _current.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    )
                  : Text(
                      _current.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _current.label,
            key: ValueKey(_current),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _current.color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+${_current.coinReward} 🪙',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (!_claimed) ...[
          if (canUpgrade) ...[
            Text(
              'Tap cup to upgrade  •  $_tapsRemaining tap${_tapsRemaining == 1 ? '' : 's'} left',
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ] else if (_tapsExhausted && _current != CupRarity.golden) ...[
            Text(
              'No more taps! Claim your reward.',
              style: TextStyle(
                  color: colorScheme.error, fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _claim,
            style: FilledButton.styleFrom(
              backgroundColor: _current.color,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _current == CupRarity.golden
                  ? 'Claim Golden Reward! 🏆'
                  : 'Claim ${_current.coinReward} Coins',
            ),
          ),
        ] else
          const Text(
            '✅ Claimed!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

/// Shows the coin cup reveal as a modal bottom sheet.
void showCoinCupReveal(
  BuildContext context, {
  CupRarity initialRarity = CupRarity.rare,
  required void Function(int coins) onClaimed,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Coin Cup!',
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          CoinCupRevealWidget(
            initialRarity: initialRarity,
            onClaimed: (coins) {
              onClaimed(coins);
              Navigator.of(sheetContext).pop();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
