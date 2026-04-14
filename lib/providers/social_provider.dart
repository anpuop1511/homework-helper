import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/social_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';

// Re-export models so existing import sites still work.
export '../models/social_models.dart';

enum ProfileVisibility { public, friendsOnly, private }
enum FriendRequestsPrivacy { everyone, nobody }

/// Represents an item in the live activity feed.
class ActivityItem {
  final String friendName;
  final String message;
  final ActivityType type;
  final DateTime timestamp;

  const ActivityItem({
    required this.friendName,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'friendName': friendName,
        'message': message,
        'type': type.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        friendName: json['friendName'] as String,
        message: json['message'] as String,
        type: ActivityType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ActivityType.other,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            json['timestamp'] as int? ?? 0),
      );
}

enum ActivityType { levelUp, focusSession, assignment, other }

extension ActivityTypeExtension on ActivityType {
  String get emoji {
    switch (this) {
      case ActivityType.levelUp:
        return '🏆';
      case ActivityType.focusSession:
        return '⏱️';
      case ActivityType.assignment:
        return '✅';
      case ActivityType.other:
        return '⭐';
    }
  }
}

/// Manages the social features: friends list, pending requests, and activity feed.
///
/// When a Firebase UID is set (via [setUid]) the provider subscribes to
/// real-time Firestore streams for friends and incoming friend requests.
/// Without a UID it falls back to locally persisted data.
class SocialProvider extends ChangeNotifier {
  static const _prefFriends = 'social_friends';
  static const _prefActivity = 'social_activity';
  static const _prefShowActivity = 'social_show_activity';
  static const _prefProfileVisibility = 'social_profile_visibility';
  static const _prefFriendRequestsPrivacy = 'social_friend_requests_privacy';

  String? _uid;
  String? _userEmail;
  String? _userName;
  String? _userUsername;

  /// Injected by [ChangeNotifierProxyProvider2] so [acceptRequest] can write
  /// the current user's real level / XP / streak to Firestore instead of
  /// hardcoded defaults.
  UserProvider? _userProvider;

  final List<Friend> _friends = [];
  final List<FriendRequest> _pendingRequests = [];
  final List<SentRequest> _sentRequests = [];
  final List<ActivityItem> _activity = [];
  bool _isLoading = false;
  bool _showStudyActivity = true;
  ProfileVisibility _profileVisibility = ProfileVisibility.public;
  FriendRequestsPrivacy _friendRequestsPrivacy = FriendRequestsPrivacy.everyone;

  StreamSubscription<List<Friend>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;
  StreamSubscription<List<SentRequest>>? _sentRequestsSub;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get pendingRequests =>
      List.unmodifiable(_pendingRequests);
  List<SentRequest> get sentRequests => List.unmodifiable(_sentRequests);
  List<ActivityItem> get activity => List.unmodifiable(_activity);
  bool get isLoading => _isLoading;
  bool get showStudyActivity => _showStudyActivity;
  ProfileVisibility get profileVisibility => _profileVisibility;
  FriendRequestsPrivacy get friendRequestsPrivacy => _friendRequestsPrivacy;

  /// True when the user has at least one pending incoming friend request.
  /// Use this to show an attention indicator on the Social tab.
  bool get hasPendingRequests => _pendingRequests.isNotEmpty;

  SocialProvider() {
    _loadLocal();
  }

  // ── UID wiring ───────────────────────────────────────────────────────────

  /// Called by [ChangeNotifierProxyProvider2] to inject the current user's
  /// gamification state so [acceptRequest] can write real stats to Firestore.
  void updateUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  /// Called when the user signs in or out.
  ///
  /// On sign-in ([uid] != null) the provider subscribes to real-time
  /// Firestore streams for friends and incoming requests.
  Future<void> setUid(
    String? uid, {
    String? email,
    String? name,
    String? username,
  }) async {
    // When only the profile fields (email, name, username) change for the
    // same UID, update them without restarting the Firestore subscriptions.
    if (_uid == uid) {
      _userEmail = email;
      _userName = name;
      _userUsername = username;
      notifyListeners();
      return;
    }
    _uid = uid;
    _userEmail = email;
    _userName = name;
    _userUsername = username;

    // Cancel existing Firestore subscriptions.
    await _friendsSub?.cancel();
    _friendsSub = null;
    await _requestsSub?.cancel();
    _requestsSub = null;
    await _sentRequestsSub?.cancel();
    _sentRequestsSub = null;

    if (uid == null) {
      _friends.clear();
      _pendingRequests.clear();
      _sentRequests.clear();
      await _loadLocal();
      return;
    }

    try {
      // Subscribe to friends stream.
      _friendsSub = DatabaseService.instance.friendsStream(uid).listen(
        (list) {
          _friends
            ..clear()
            ..addAll(list);
          notifyListeners();
        },
        onError: (_) {/* keep existing list */},
      );

      // Subscribe to incoming requests stream.
      // Track the previous IDs so we can trigger a notification only for
      // requests that are genuinely new (M-3: don't blindly use list.last).
      Set<String> prevRequestIds = {};
      _requestsSub =
          DatabaseService.instance.pendingRequestsStream(uid).listen(
        (list) {
          final currentIds = {for (final r in list) r.id};
          final newRequests = prevRequestIds.isNotEmpty
              ? list.where((r) => !prevRequestIds.contains(r.id)).toList()
              : <FriendRequest>[];
          _pendingRequests
            ..clear()
            ..addAll(list);
          prevRequestIds = currentIds;
          notifyListeners();
          // Show an in-app notification for each genuinely new request.
          for (final newReq in newRequests) {
            _onNewFriendRequest(newReq);
          }
        },
        onError: (_) {/* keep existing list */},
      );

      // Subscribe to outgoing (sent) requests stream so the Pending tab
      // updates in real-time without requiring a manual refresh.
      _sentRequestsSub =
          DatabaseService.instance.sentRequestsStream(uid).listen(
        (list) {
          _sentRequests
            ..clear()
            ..addAll(list);
          notifyListeners();
        },
        onError: (_) {/* keep existing list */},
      );

      // Load privacy settings from cloud.
      // Values may be stored as strings (name) or legacy integers (index).
      // Always prefer string-name lookup; fall back to index for old records (M-5).
      try {
        final data = await DatabaseService.instance.getUserData(uid);
        final pvRaw = data?['profileVisibility'];
        if (pvRaw is String) {
          _profileVisibility = ProfileVisibility.values.firstWhere(
            (e) => e.name == pvRaw,
            orElse: () => ProfileVisibility.public,
          );
        } else if (pvRaw is int &&
            pvRaw >= 0 &&
            pvRaw < ProfileVisibility.values.length) {
          _profileVisibility = ProfileVisibility.values[pvRaw];
        }
        final frpRaw = data?['friendRequestsPrivacy'];
        if (frpRaw is String) {
          _friendRequestsPrivacy = FriendRequestsPrivacy.values.firstWhere(
            (e) => e.name == frpRaw,
            orElse: () => FriendRequestsPrivacy.everyone,
          );
        } else if (frpRaw is int &&
            frpRaw >= 0 &&
            frpRaw < FriendRequestsPrivacy.values.length) {
          _friendRequestsPrivacy = FriendRequestsPrivacy.values[frpRaw];
        }
        notifyListeners();
      } catch (_) {}
    } catch (_) {
      // Firestore unavailable – stay in local mode.
    }
  }

  // ── Local persistence ────────────────────────────────────────────────────

  /// Fires a local notification when a new friend request arrives.
  void _onNewFriendRequest(FriendRequest request) {
    final handle = request.fromUsername.isNotEmpty
        ? request.fromUsername
        : request.fromEmail.split('@').first;
    NotificationService.instance
        .showFriendRequestNotification(handle)
        .ignore();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _showStudyActivity = prefs.getBool(_prefShowActivity) ?? true;

    // Clear before populating to prevent duplicates if called concurrently (M-4).
    _friends.clear();
    _activity.clear();

    // Load friends from local cache (used in offline / guest mode).
    final friendsJson = prefs.getStringList(_prefFriends) ?? [];
    for (final raw in friendsJson) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _friends.add(Friend.fromJson(map));
      } catch (_) {}
    }
    // Load activity.
    final activityJson = prefs.getStringList(_prefActivity) ?? [];
    for (final raw in activityJson) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _activity.add(ActivityItem.fromJson(map));
      } catch (_) {}
    }
    final pvIndex = prefs.getInt(_prefProfileVisibility) ?? 0;
    _profileVisibility = ProfileVisibility.values[pvIndex.clamp(0, ProfileVisibility.values.length - 1)];
    final frpIndex = prefs.getInt(_prefFriendRequestsPrivacy) ?? 0;
    _friendRequestsPrivacy = FriendRequestsPrivacy.values[frpIndex.clamp(0, FriendRequestsPrivacy.values.length - 1)];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefFriends,
      _friends.map((f) => json.encode(f.toJson())).toList(),
    );
    await prefs.setStringList(
      _prefActivity,
      _activity.map((a) => json.encode(a.toJson())).toList(),
    );
  }

  // ── Friend requests ──────────────────────────────────────────────────────

  /// Sends a friend request to the user with [@handle].
  ///
  /// When a Firebase UID is available, looks up the target user by username in
  /// Firestore and writes a `friend_requests` document.  If the input looks
  /// like an email address (contains `@`), it falls back to an email-based
  /// lookup automatically.  In guest/offline mode, falls back to a local
  /// placeholder entry.
  ///
  /// Returns an error string on failure, or null on success.
  Future<String?> sendFriendRequestByUsername(String handle) async {
    // Strip leading @ if user typed it.
    final trimmed = handle.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (trimmed.isEmpty) return 'Please enter a @username.';

    // If the input looks like an email address, delegate to email lookup.
    if (trimmed.contains('@')) {
      return sendFriendRequest(trimmed);
    }

    if (_uid != null) {
      // Check not adding yourself.
      if (_userUsername?.toLowerCase() == trimmed) {
        return 'You cannot add yourself as a friend.';
      }
      if (_friends.any((f) => f.username.toLowerCase() == trimmed)) {
        return 'You are already friends with this person.';
      }

      _isLoading = true;
      notifyListeners();

      try {
        final toUid =
            await DatabaseService.instance.lookupUidByUsername(trimmed);
        if (toUid == null) {
          _isLoading = false;
          notifyListeners();
          return 'No user found with @$trimmed.';
        }
        if (toUid == _uid) {
          _isLoading = false;
          notifyListeners();
          return 'You cannot add yourself as a friend.';
        }
        // Fetch the target user's email for the request document.
        final userData =
            await DatabaseService.instance.getUserData(toUid);
        final toEmail = userData?['email'] as String? ?? '';

        await DatabaseService.instance.sendFriendRequest(
          fromUid: _uid!,
          toUid: toUid,
          fromEmail: _userEmail ?? '',
          toEmail: toEmail,
          fromUsername: _userUsername ?? '',
          fromName: _userName ?? '',
          toUsername: trimmed,
        );
        _isLoading = false;
        notifyListeners();
        return null; // success
      } catch (_) {
        _isLoading = false;
        notifyListeners();
        return 'Could not send request. Please check your connection.';
      }
    }

    // Offline / guest fallback: add a local placeholder.
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    final newFriend = Friend(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      email: '',
      username: trimmed,
      level: 1,
      totalXp: 0,
      streak: 0,
    );
    _friends.add(newFriend);
    _isLoading = false;
    notifyListeners();
    await _save();
    return null;
  }

  /// Sends a friend request to the user with [email].
  /// Kept for backward compatibility; prefer [sendFriendRequestByUsername].
  ///
  /// Returns an error string on failure, or null on success.
  Future<String?> sendFriendRequest(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Please enter an email address.';
    if (!trimmed.contains('@')) return 'Please enter a valid email address.';
    if (_friends.any((f) => f.email.toLowerCase() == trimmed)) {
      return 'You are already friends with this person.';
    }
    if (_uid != null && _userEmail?.toLowerCase() == trimmed) {
      return 'You cannot add yourself as a friend.';
    }
    if (_pendingRequests.any((r) => r.fromEmail.toLowerCase() == trimmed)) {
      return 'You already have a pending request from this person.';
    }

    _isLoading = true;
    notifyListeners();

    if (_uid != null) {
      // Firestore mode: look up the target user by email.
      try {
        final userData =
            await DatabaseService.instance.lookupUserByEmail(trimmed);
        if (userData == null) {
          _isLoading = false;
          notifyListeners();
          return 'No user found with that email address.';
        }
        final toUid = userData['uid'] as String;
        if (toUid == _uid) {
          _isLoading = false;
          notifyListeners();
          return 'You cannot add yourself as a friend.';
        }
        await DatabaseService.instance.sendFriendRequest(
          fromUid: _uid!,
          toUid: toUid,
          fromEmail: _userEmail ?? '',
          toEmail: trimmed,
          fromUsername: _userUsername ?? '',
          fromName: _userName ?? '',
        );
        _isLoading = false;
        notifyListeners();
        return null; // success
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        return 'Could not send request. Please check your connection.';
      }
    }

    // Offline / guest fallback: add a local placeholder.
    await Future.delayed(const Duration(milliseconds: 500));
    final newFriend = Friend(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed.split('@').first,
      email: trimmed,
      level: 1,
      totalXp: 0,
      streak: 0,
    );
    _friends.add(newFriend);
    _isLoading = false;
    notifyListeners();
    await _save();
    return null;
  }

  /// Accepts an incoming friend request.
  ///
  /// Performs an optimistic removal from [_pendingRequests] so the UI updates
  /// instantly, then commits the change to Firestore.  If Firestore fails (e.g.
  /// the request was cancelled by the sender between load and tap), the request
  /// is restored and an exception is rethrown so the caller can show feedback.
  Future<void> acceptRequest(FriendRequest request) async {
    if (_uid == null) return;

    // Optimistic update — remove immediately for instant UI feedback.
    final idx = _pendingRequests.indexWhere((r) => r.id == request.id);
    if (idx == -1) {
      // The request is already gone (cancelled / accepted elsewhere) – ignore.
      return;
    }
    _pendingRequests.removeAt(idx);
    notifyListeners();

    try {
      await DatabaseService.instance.acceptFriendRequest(
        request,
        currentUserData: {
          'uid': _uid!,
          'name': _userName ?? _userEmail?.split('@').first ?? '',
          'email': _userEmail ?? '',
          'username': _userUsername ?? '',
          'level': _userProvider?.level ?? 1,
          'totalXp': _userProvider?.totalXp ?? 0,
          'streak': _userProvider?.streak ?? 0,
          if ((_userProvider?.passType ?? 'free') != 'free')
            'passType': _userProvider!.passType,
          if ((_userProvider?.equippedBadge ?? '').isNotEmpty)
            'equippedBadge': _userProvider!.equippedBadge,
        },
      );
    } catch (e) {
      // Restore the request in the list so the user can try again.
      if (idx <= _pendingRequests.length) {
        _pendingRequests.insert(idx, request);
      } else {
        _pendingRequests.add(request);
      }
      notifyListeners();
      // Rethrow so the UI can show a graceful error message.
      rethrow;
    }
  }

  /// Declines an incoming friend request.
  Future<void> declineRequest(FriendRequest request) async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.declineFriendRequest(request.id, targetUid: _uid);
    } catch (_) {}
  }

  /// Cancels an outgoing (sent) friend request.
  ///
  /// Optimistically removes the request from the local [_sentRequests] list for
  /// instant UI feedback; the Firestore stream will confirm the deletion.
  Future<void> cancelSentRequest(SentRequest request) async {
    if (_uid == null) return;
    _sentRequests.removeWhere((r) => r.id == request.id);
    notifyListeners();
    try {
      await DatabaseService.instance.cancelSentRequest(request.id);
    } catch (_) {
      // The stream will restore the request if the delete fails.
    }
  }

  /// Removes [friend] from the friends list.
  Future<void> removeFriend(String id) async {
    // Save a snapshot for rollback in case the backend call fails.
    final snapshot = List<Friend>.from(_friends);

    // Optimistically remove from local state immediately for instant UI feedback.
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();

    if (_uid != null) {
      try {
        await DatabaseService.instance.removeFriend(_uid!, id);
      } catch (e) {
        debugPrint('[SocialProvider] removeFriend error: $e');
        // Roll back to the pre-removal snapshot so the UI stays consistent
        // with the server state.  The Firestore real-time stream will also
        // re-emit the unchanged friends list once connectivity is restored.
        _friends
          ..clear()
          ..addAll(snapshot);
        notifyListeners();
      }
    } else {
      await _save();
    }
  }

  // ── Privacy preference ───────────────────────────────────────────────────

  /// Updates the "Show Study Activity to Friends" preference.
  Future<void> setShowStudyActivity(bool value) async {
    if (_showStudyActivity == value) return;
    _showStudyActivity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowActivity, value);
  }

  Future<void> setProfileVisibility(ProfileVisibility v) async {
    if (_profileVisibility == v) return;
    _profileVisibility = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefProfileVisibility, v.index);
    if (_uid != null) {
      try {
        await DatabaseService.instance.savePrivacySettings(
          _uid!,
          profileVisibility: v.name,
          friendRequestsPrivacy: _friendRequestsPrivacy.name,
        );
      } catch (_) {}
    }
  }

  Future<void> setFriendRequestsPrivacy(FriendRequestsPrivacy v) async {
    if (_friendRequestsPrivacy == v) return;
    _friendRequestsPrivacy = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFriendRequestsPrivacy, v.index);
    if (_uid != null) {
      try {
        await DatabaseService.instance.savePrivacySettings(
          _uid!,
          profileVisibility: _profileVisibility.name,
          friendRequestsPrivacy: v.name,
        );
      } catch (_) {}
    }
  }

  // ── Activity feed (demo / future) ────────────────────────────────────────

  /// Adds a sample activity item (used for demo purposes).
  void addSampleActivity() {
    const samples = [
      ('Alex', 'levelled up to Level 5! 🎉', ActivityType.levelUp),
      ('Sam', 'completed a 25-min focus session 🔥', ActivityType.focusSession),
      ('Jordan', 'finished 3 assignments today ✅', ActivityType.assignment),
    ];
    final sample = samples[_activity.length % samples.length];
    _activity.insert(
      0,
      ActivityItem(
        friendName: sample.$1,
        message: sample.$2,
        type: sample.$3,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    _save();
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    _sentRequestsSub?.cancel();
    super.dispose();
  }
}
