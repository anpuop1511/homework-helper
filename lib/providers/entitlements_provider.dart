import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entitlement_model.dart';
import '../services/database_service.dart';

/// Maximum number of classes a free-tier user may create.
const int kFreeClassLimit = 20;

/// Maximum number of user-defined subjects a free-tier user may create.
/// (Canonical subjects are predefined and do not count against this limit.)
const int kFreeSubjectLimit = 20;

/// Manages the user's [SubscriptionEntitlement] and provides feature-gate
/// helpers for the rest of the app.
///
/// Subscribes to a real-time Firestore snapshot at
/// `users/{uid}/entitlements/subscription` and caches the latest value in
/// [SharedPreferences] so gating is available even when offline.
///
/// Defaults to [SubscriptionEntitlement.free] when:
///   - No UID is set (guest mode).
///   - The entitlement document does not exist.
///   - Firebase is unavailable on cold start (uses cached value).
class EntitlementsProvider extends ChangeNotifier {
  static const _kPrefCacheKey = 'entitlement_cache_v1';

  SubscriptionEntitlement _entitlement = SubscriptionEntitlement.free;
  String? _uid;
  StreamSubscription<SubscriptionEntitlement?>? _sub;

  // ── Public state ──────────────────────────────────────────────────────────

  /// The current entitlement; always non-null (defaults to free).
  SubscriptionEntitlement get entitlement => _entitlement;

  /// Convenience: the active tier.
  EntitlementTier get tier => _entitlement.tier;

  /// Whether the user has an active Helper+ or higher subscription.
  bool get isPlus => _entitlement.hasPlus;

  /// Whether the user has an active Helper Pass subscription.
  bool get isPass => _entitlement.hasPass;

  // ── Feature-gate helpers ─────────────────────────────────────────────────

  /// True when the user can create additional classes.
  ///
  /// [currentCount] is the number of classes the user currently has.
  bool canAddClass(int currentCount) =>
      isPlus || currentCount < kFreeClassLimit;

  /// True when the user can create additional subjects.
  ///
  /// [currentCount] is the number of user-defined subjects.
  bool canAddSubject(int currentCount) =>
      isPlus || currentCount < kFreeSubjectLimit;

  /// True when the user may access the repeatable-task feature.
  bool get canUseRepeatableTasks => isPlus;

  /// True when the user may access premium (non-default) color vibes.
  bool get canUsePremiumThemes => isPlus;

  /// True when the user may use the custom gradient-theme builder.
  bool get canUseGradientThemeBuilder => isPlus;

  /// True when the user may use the custom light/dark theme builder.
  bool get canUseCustomLightDarkTheme => isPlus;

  /// True when Pass-exclusive features (battle pass, BYOK non-Gemini, badge)
  /// are accessible.
  bool get canUsePassFeatures => isPass;

  // ── UID management ────────────────────────────────────────────────────────

  /// Called by [ChangeNotifierProxyProvider] whenever the authenticated UID
  /// changes (sign-in, sign-out, etc.).
  Future<void> setUid(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;

    // Cancel any existing Firestore stream.
    await _sub?.cancel();
    _sub = null;

    if (uid == null) {
      // Signed out — restore local cache if present, else default to free.
      await _loadCached();
      return;
    }

    // Load the locally-cached value first so the UI doesn't flash.
    await _loadCached();

    // Then subscribe to real-time Firestore updates.
    _sub = DatabaseService.instance
        .entitlementsStream(uid)
        .handleError((Object e) {
          debugPrint('[EntitlementsProvider] Firestore error: $e');
        })
        .listen(_onEntitlementUpdate);
  }

  void _onEntitlementUpdate(SubscriptionEntitlement? incoming) {
    final resolved = incoming ?? SubscriptionEntitlement.free;
    _entitlement = resolved;
    notifyListeners();
    _saveCache(resolved);
  }

  // ── Local cache ───────────────────────────────────────────────────────────

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefCacheKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _entitlement = SubscriptionEntitlement.fromPrefsMap(map);
      } else {
        _entitlement = SubscriptionEntitlement.free;
      }
    } catch (_) {
      _entitlement = SubscriptionEntitlement.free;
    }
    notifyListeners();
  }

  Future<void> _saveCache(SubscriptionEntitlement e) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefCacheKey, jsonEncode(e.toPrefsMap()));
    } catch (_) {
      // Cache write failure is non-fatal.
    }
  }

  // ── Admin/debug helpers ───────────────────────────────────────────────────

  /// Clears the local cache and resets to free. Useful in dev resets.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefCacheKey);
    _entitlement = SubscriptionEntitlement.free;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
