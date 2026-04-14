import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// A shop where players can spend coins on cosmetic items.
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

class _ShopItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int price;
  final bool isNameplate;

  const _ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.price,
    this.isNameplate = false,
  });
}

const _shopItems = [
  _ShopItem(
    id: 'spring_petal_badge',
    name: 'Spring Petal Badge',
    description: 'A delicate cherry blossom badge for your profile.',
    emoji: '🌸',
    price: 150,
  ),
  _ShopItem(
    id: 'blue_sky',
    name: 'Blue Sky Nameplate',
    description: 'A serene sky-blue nameplate.',
    emoji: '🩵',
    price: 200,
    isNameplate: true,
  ),
  _ShopItem(
    id: 'daffodil_yellow',
    name: 'Daffodil Yellow Nameplate',
    description: 'A bright daffodil-yellow nameplate.',
    emoji: '🌼',
    price: 200,
    isNameplate: true,
  ),
  _ShopItem(
    id: 'study_streak_frame',
    name: 'Study Streak Frame',
    description: 'Show off your dedication with a flame-bordered frame.',
    emoji: '🔥',
    price: 250,
  ),
  _ShopItem(
    id: 'rainbow_name_color',
    name: 'Rainbow Name Color',
    description: 'Make your name shine in rainbow colors.',
    emoji: '🌈',
    price: 300,
  ),
];

class _ShopBody extends StatelessWidget {
  const _ShopBody();

  void _purchase(BuildContext context, _ShopItem item) {
    final user = context.read<UserProvider>();

    if (user.unlockedCosmetics.contains(item.id)) {
      if (item.isNameplate) {
        user.setActiveNameplate(item.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.emoji} ${item.name} equipped!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already own this item!')),
        );
      }
      return;
    }

    final success = user.spendCoins(item.price);
    if (success) {
      user.unlockCosmetic(item.id);
      if (item.isNameplate) {
        user.setActiveNameplate(item.name);
      }
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Coin balance header
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

        Text(
          'Spring Collection',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Limited items — available this season only!',
          style: TextStyle(
              fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        ..._shopItems.map((item) {
          final owned = user.unlockedCosmetics.contains(item.id);
          return _ShopItemCard(
            item: item,
            owned: owned,
            colorScheme: colorScheme,
            onTap: () => _purchase(context, item),
          );
        }),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final _ShopItem item;
  final bool owned;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ShopItemCard({
    required this.item,
    required this.owned,
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
          Text(item.emoji, style: const TextStyle(fontSize: 32)),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          owned
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✓ Owned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
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
