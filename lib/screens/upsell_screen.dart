import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/entitlement_model.dart';
import '../providers/entitlements_provider.dart';

/// Upsell screen for Homework Helper+ and Helper Pass subscriptions.
///
/// On **Android** it shows the tier benefits and placeholder purchase buttons
/// (the actual Google Play billing integration should be wired here once
/// `in_app_purchase` is added).
///
/// On **Web** it shows the current entitlement status and a message to
/// subscribe on Android.
class UpsellScreen extends StatelessWidget {
  const UpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entitlements = context.watch<EntitlementsProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Subscription',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // ── Current tier banner ───────────────────────────────────
            _CurrentTierBanner(
              tier: entitlements.tier,
              isActive: entitlements.entitlement.isActive,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 20),

            // ── Web: subscribe on Android message ─────────────────────
            if (kIsWeb && !entitlements.isPlus) ...[
              _WebMessageCard(colorScheme: colorScheme),
              const SizedBox(height: 20),
            ],

            // ── Tier comparison cards ─────────────────────────────────
            _TierCard(
              emoji: '🆓',
              name: 'Free',
              price: 'Always free',
              highlightColor: colorScheme.surfaceContainerHigh,
              isCurrentTier: entitlements.tier == EntitlementTier.free,
              features: const [
                _Feature('Up to 20 classes', included: true),
                _Feature('Up to 20 subjects', included: true),
                _Feature('Standard themes', included: true),
                _Feature('Repeatable tasks', included: false),
                _Feature('Premium themes', included: false),
                _Feature('Custom theme builders', included: false),
                _Feature('Monthly coins', included: false),
              ],
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _TierCard(
              emoji: '✨',
              name: 'Homework Helper+',
              price: r'$1.99/month  ·  $19.99/year',
              trialText: '14-day free trial',
              ladderPromoText:
                  'Complete the Ladder event → one-time 30-day free trial',
              highlightColor: const Color(0xFF6750A4),
              isCurrentTier: entitlements.tier == EntitlementTier.plus,
              features: const [
                _Feature('Unlimited classes & subjects', included: true),
                _Feature('Repeatable tasks', included: true),
                _Feature('2 premium themes (Neon Sunrise, Deep Ocean)',
                    included: true),
                _Feature('Custom gradient theme builder', included: true),
                _Feature('Custom light/dark theme builder', included: true),
                _Feature('500 coins on billing date', included: true),
              ],
              actionWidget: kIsWeb
                  ? null
                  : _PurchaseButton(
                      label: 'Start Free Trial',
                      // TODO(billing): wire up Google Play in_app_purchase
                      // SKU: helper_plus_monthly_1_99 (14-day trial)
                      onTap: () => _showComingSoon(context),
                      colorScheme: colorScheme,
                    ),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _TierCard(
              emoji: '🏅',
              name: 'Helper Pass',
              price: r'$2.99/month',
              trialText: '7-day free trial · then $1.99/mo for 2 months',
              ladderPromoText:
                  'Complete the Ladder event → one-time 14-day free trial',
              highlightColor: const Color(0xFFB8860B),
              isCurrentTier: entitlements.tier == EntitlementTier.pass,
              features: const [
                _Feature('Everything in Helper+', included: true),
                _Feature('Season Battle Pass auto-activated', included: true),
                _Feature('750 coins on billing date', included: true),
                _Feature('Pass badge', included: true),
                _Feature('AI model choice (BYOK non-Gemini)', included: true),
              ],
              actionWidget: kIsWeb
                  ? null
                  : _PurchaseButton(
                      label: 'Start Free Trial',
                      // TODO(billing): wire up Google Play in_app_purchase
                      // SKU: helper_pass_monthly_2_99 (7-day trial)
                      onTap: () => _showComingSoon(context),
                      colorScheme: colorScheme,
                    ),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 20),

            // ── Restore purchases (Android only) ──────────────────────
            if (!kIsWeb)
              _RestorePurchasesButton(colorScheme: colorScheme),

            const SizedBox(height: 8),
            _DisclaimerText(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        // TODO(billing): remove this snackbar once Google Play billing is wired.
        content: Text(
          'In-app purchase coming soon! '
          'Billing integration will be added in a future update.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Current tier banner ───────────────────────────────────────────────────────

class _CurrentTierBanner extends StatelessWidget {
  final EntitlementTier tier;
  final bool isActive;
  final ColorScheme colorScheme;

  const _CurrentTierBanner({
    required this.tier,
    required this.isActive,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final String emoji;
    final Color bgColor;
    switch (tier) {
      case EntitlementTier.plus:
        label = 'Homework Helper+';
        emoji = '✨';
        bgColor = const Color(0xFF6750A4);
        break;
      case EntitlementTier.pass:
        label = 'Helper Pass';
        emoji = '🏅';
        bgColor = const Color(0xFFB8860B);
        break;
      case EntitlementTier.free:
        label = 'Free';
        emoji = '🆓';
        bgColor = colorScheme.surfaceContainerHigh;
        break;
    }

    final textColor = tier == EntitlementTier.free
        ? colorScheme.onSurface
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: textColor.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (tier != EntitlementTier.free)
                  Text(
                    isActive ? 'Active' : 'Expired',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isActive
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Web message card ──────────────────────────────────────────────────────────

class _WebMessageCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _WebMessageCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('📱', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscribe on Android',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purchases are made through the Android app via Google Play. '
                  'Once you subscribe on Android, your Helper+ or Helper Pass '
                  'benefits will appear here automatically.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: colorScheme.onTertiaryContainer.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier card ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String price;
  final String? trialText;
  final String? ladderPromoText;
  final Color highlightColor;
  final bool isCurrentTier;
  final List<_Feature> features;
  final Widget? actionWidget;
  final ColorScheme colorScheme;

  const _TierCard({
    required this.emoji,
    required this.name,
    required this.price,
    this.trialText,
    this.ladderPromoText,
    required this.highlightColor,
    required this.isCurrentTier,
    required this.features,
    this.actionWidget,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentTier
              ? highlightColor
              : colorScheme.outlineVariant.withAlpha(80),
          width: isCurrentTier ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: highlightColor.withAlpha(isCurrentTier ? 40 : 20),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isCurrentTier) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: highlightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Current',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        price,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (trialText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          trialText!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: highlightColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Feature list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              children: features.map((f) => _FeatureRow(feature: f)).toList(),
            ),
          ),
          // Ladder promo text
          if (ladderPromoText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ladderPromoText!,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action button
          if (actionWidget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: actionWidget,
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _Feature {
  final String text;
  final bool included;
  const _Feature(this.text, {required this.included});
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            feature.included
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            size: 18,
            color: feature.included
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withAlpha(120),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature.text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: feature.included
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withAlpha(160),
                decoration: feature.included
                    ? null
                    : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Purchase button ───────────────────────────────────────────────────────────

class _PurchaseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PurchaseButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.shopping_bag_rounded, size: 18),
        label: Text(
          label,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── Restore purchases ─────────────────────────────────────────────────────────

class _RestorePurchasesButton extends StatelessWidget {
  final ColorScheme colorScheme;
  const _RestorePurchasesButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        // TODO(billing): call in_app_purchase restorePurchases() here.
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Restore purchases coming soon once billing is integrated.'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        icon: const Icon(Icons.restore_rounded, size: 18),
        label: Text(
          'Restore Purchases',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── Disclaimer text ───────────────────────────────────────────────────────────

class _DisclaimerText extends StatelessWidget {
  final ColorScheme colorScheme;
  const _DisclaimerText({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Subscriptions auto-renew unless cancelled at least 24 hours before the '
      'end of the current period. Manage subscriptions in your Google Play '
      'account settings.',
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: colorScheme.onSurfaceVariant.withAlpha(160),
      ),
    );
  }
}
