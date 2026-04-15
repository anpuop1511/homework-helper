import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription tiers available in Homework Helper.
enum EntitlementTier {
  /// Default – no active subscription.
  free,

  /// Homework Helper+ (monthly $1.99 / yearly $19.99).
  plus,

  /// Helper Pass (higher tier, includes everything in plus).
  pass;

  /// Parses a raw Firestore string value, defaulting to [free] on error.
  static EntitlementTier fromString(String? value) {
    switch (value) {
      case 'plus':
        return EntitlementTier.plus;
      case 'pass':
        return EntitlementTier.pass;
      default:
        return EntitlementTier.free;
    }
  }

  /// Whether this tier includes Helper+ benefits.
  bool get hasPlus => this == plus || this == pass;

  /// Whether this tier includes Helper Pass benefits.
  bool get hasPass => this == pass;
}

/// Firestore-backed subscription entitlement for a user.
///
/// Stored at `users/{uid}/entitlements/subscription`.
///
/// Fields:
///   - `tier`: 'free' | 'plus' | 'pass'
///   - `active`: bool (optional; derived from expiresAt when present)
///   - `expiresAt`: Timestamp | null
///   - `updatedAt`: server timestamp
///   - `platform`: e.g. 'android_google_play'
///   - `earned_plus_30d_trial_from_ladder`: bool (one-time promo flag)
///   - `earned_pass_14d_trial_from_ladder`: bool (one-time promo flag)
class SubscriptionEntitlement {
  final EntitlementTier tier;

  /// Whether the subscription is currently active.
  ///
  /// If [expiresAt] is provided, derived as `expiresAt.isAfter(now)`.
  /// If [expiresAt] is null (lifetime/debug), [explicit] value is used.
  final DateTime? expiresAt;

  /// Explicitly-set active flag (used when expiresAt is absent).
  final bool? explicitActive;

  /// When this entitlement record was last updated in Firestore.
  final DateTime? updatedAt;

  /// Platform that created this entitlement, e.g. `'android_google_play'`.
  final String? platform;

  /// True once the user has used the one-time 30-day Helper+ trial earned
  /// by completing the Assignments Ladder.
  final bool earnedPlus30dTrialFromLadder;

  /// True once the user has used the one-time 14-day Helper Pass trial earned
  /// by completing the Assignments Ladder.
  final bool earnedPass14dTrialFromLadder;

  const SubscriptionEntitlement({
    this.tier = EntitlementTier.free,
    this.expiresAt,
    this.explicitActive,
    this.updatedAt,
    this.platform,
    this.earnedPlus30dTrialFromLadder = false,
    this.earnedPass14dTrialFromLadder = false,
  });

  /// The sentinel value returned when no entitlement document exists.
  static const SubscriptionEntitlement free = SubscriptionEntitlement();

  /// Returns true when the subscription is currently active.
  bool get isActive {
    if (expiresAt != null) {
      return expiresAt!.isAfter(DateTime.now());
    }
    return explicitActive ?? (tier != EntitlementTier.free);
  }

  /// True when the user has an active Helper+ or higher entitlement.
  bool get hasPlus => tier.hasPlus && isActive;

  /// True when the user has an active Helper Pass entitlement.
  bool get hasPass => tier.hasPass && isActive;

  /// Deserialises from a Firestore [DocumentSnapshot].
  factory SubscriptionEntitlement.fromFirestore(
      Map<String, dynamic> data) {
    DateTime? expiresAt;
    final rawExpiry = data['expiresAt'];
    if (rawExpiry is Timestamp) {
      expiresAt = rawExpiry.toDate();
    } else if (rawExpiry is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(rawExpiry);
    }

    DateTime? updatedAt;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is Timestamp) {
      updatedAt = rawUpdated.toDate();
    }

    return SubscriptionEntitlement(
      tier: EntitlementTier.fromString(data['tier'] as String?),
      expiresAt: expiresAt,
      explicitActive: data['active'] as bool?,
      updatedAt: updatedAt,
      platform: data['platform'] as String?,
      earnedPlus30dTrialFromLadder:
          (data['earned_plus_30d_trial_from_ladder'] as bool?) ?? false,
      earnedPass14dTrialFromLadder:
          (data['earned_pass_14d_trial_from_ladder'] as bool?) ?? false,
    );
  }

  /// Serialises to a Firestore-compatible map (for writes).
  Map<String, dynamic> toFirestore() => {
        'tier': tier.name,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        if (explicitActive != null) 'active': explicitActive,
        'updatedAt': FieldValue.serverTimestamp(),
        if (platform != null) 'platform': platform,
        'earned_plus_30d_trial_from_ladder': earnedPlus30dTrialFromLadder,
        'earned_pass_14d_trial_from_ladder': earnedPass14dTrialFromLadder,
      };

  /// Serialises to a flat map for [SharedPreferences] caching.
  /// Uses simple types (String / bool / int) only.
  Map<String, dynamic> toPrefsMap() => {
        'tier': tier.name,
        if (expiresAt != null) 'expiresAtMs': expiresAt!.millisecondsSinceEpoch,
        if (explicitActive != null) 'active': explicitActive,
        if (platform != null) 'platform': platform,
        'earned_plus_30d_trial_from_ladder': earnedPlus30dTrialFromLadder,
        'earned_pass_14d_trial_from_ladder': earnedPass14dTrialFromLadder,
      };

  /// Deserialises from the flat map stored in [SharedPreferences].
  factory SubscriptionEntitlement.fromPrefsMap(Map<String, dynamic> map) {
    DateTime? expiresAt;
    final expiresAtMs = map['expiresAtMs'] as int?;
    if (expiresAtMs != null) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
    }
    return SubscriptionEntitlement(
      tier: EntitlementTier.fromString(map['tier'] as String?),
      expiresAt: expiresAt,
      explicitActive: map['active'] as bool?,
      platform: map['platform'] as String?,
      earnedPlus30dTrialFromLadder:
          (map['earned_plus_30d_trial_from_ladder'] as bool?) ?? false,
      earnedPass14dTrialFromLadder:
          (map['earned_pass_14d_trial_from_ladder'] as bool?) ?? false,
    );
  }

  @override
  String toString() =>
      'SubscriptionEntitlement(tier: ${tier.name}, isActive: $isActive, '
      'expiresAt: $expiresAt, platform: $platform)';
}
