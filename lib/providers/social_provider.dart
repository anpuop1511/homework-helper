import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/social_models.dart';
import '../services/database_service.dart';

// Re-export models so existing import sites still work.
export '../models/social_models.dart';

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

  String? _uid;
  String? _userEmail;
  String? _userName;

  final List<Friend> _friends = [];
  final List<FriendRequest> _pendingRequests = [];
  final List<ActivityItem> _activity = [];
  bool _isLoading = false;
  bool _showStudyActivity = true;

  StreamSubscription<List<Friend>>? _friendsSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get pendingRequests =>
      List.unmodifiable(_pendingRequests);
  List<ActivityItem> get activity => List.unmodifiable(_activity);
  bool get isLoading => _isLoading;
  bool get showStudyActivity => _showStudyActivity;

  SocialProvider() {
    _loadLocal();
  }

  // ── UID wiring ───────────────────────────────────────────────────────────

  /// Called when the user signs in or out.
  ///
  /// On sign-in ([uid] != null) the provider subscribes to real-time
  /// Firestore streams for friends and incoming requests.
  Future<void> setUid(
    String? uid, {
    String? email,
    String? name,
  }) async {
    if (_uid == uid) return;
    _uid = uid;
    _userEmail = email;
    _userName = name;

    // Cancel existing Firestore subscriptions.
    await _friendsSub?.cancel();
    _friendsSub = null;
    await _requestsSub?.cancel();
    _requestsSub = null;

    if (uid == null) {
      _friends.clear();
      _pendingRequests.clear();
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
      _requestsSub =
          DatabaseService.instance.pendingRequestsStream(uid).listen(
        (list) {
          _pendingRequests
            ..clear()
            ..addAll(list);
          notifyListeners();
        },
        onError: (_) {/* keep existing list */},
      );
    } catch (_) {
      // Firestore unavailable – stay in local mode.
    }
  }

  // ── Local persistence ────────────────────────────────────────────────────

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _showStudyActivity = prefs.getBool(_prefShowActivity) ?? true;

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

  /// Sends a friend request to the user with [email].
  ///
  /// When a Firebase UID is available, looks up the target user by email in
  /// Firestore and writes a `friend_requests` document.  In guest/offline
  /// mode, falls back to a local placeholder entry.
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
  Future<void> acceptRequest(FriendRequest request) async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.acceptFriendRequest(
        request,
        currentUserData: {
          'uid': _uid!,
          'name': _userName ?? _userEmail?.split('@').first ?? 'Student',
          'email': _userEmail ?? '',
          'level': 1,
          'totalXp': 0,
          'streak': 0,
        },
      );
    } catch (_) {
      // Silently ignore Firestore errors.
    }
  }

  /// Declines an incoming friend request.
  Future<void> declineRequest(FriendRequest request) async {
    if (_uid == null) return;
    try {
      await DatabaseService.instance.declineFriendRequest(request.id);
    } catch (_) {}
  }

  /// Removes [friend] from the friends list.
  Future<void> removeFriend(String id) async {
    if (_uid != null) {
      try {
        await DatabaseService.instance.removeFriend(_uid!, id);
      } catch (_) {}
    } else {
      _friends.removeWhere((f) => f.id == id);
      notifyListeners();
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
    super.dispose();
  }
}
