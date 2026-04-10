import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents a friend in the user's social network.
class Friend {
  final String id;
  final String name;
  final String email;
  final int level;
  final int totalXp;
  final int streak;

  const Friend({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.totalXp,
    required this.streak,
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'level': level,
        'totalXp': totalXp,
        'streak': streak,
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        level: json['level'] as int? ?? 1,
        totalXp: json['totalXp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
      );
}

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

/// Manages the social features: friends list and activity feed.
/// Data is persisted locally via [SharedPreferences].
/// In a production app this would sync with Firestore.
class SocialProvider extends ChangeNotifier {
  static const _prefFriends = 'social_friends';
  static const _prefActivity = 'social_activity';

  final List<Friend> _friends = [];
  final List<ActivityItem> _activity = [];
  bool _isLoading = false;
  String? _pendingRequest;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<ActivityItem> get activity => List.unmodifiable(_activity);
  bool get isLoading => _isLoading;
  String? get pendingRequest => _pendingRequest;

  SocialProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Load friends
    final friendsJson = prefs.getStringList(_prefFriends) ?? [];
    for (final raw in friendsJson) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _friends.add(Friend.fromJson(map));
      } catch (_) {}
    }
    // Load activity
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

  /// Sends a friend request to the user with [email].
  /// In production this would look up the user in Firestore.
  Future<String?> sendFriendRequest(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Please enter an email address.';
    if (!trimmed.contains('@')) return 'Please enter a valid email address.';
    if (_friends.any((f) => f.email.toLowerCase() == trimmed)) {
      return 'You are already friends with this person.';
    }
    _isLoading = true;
    notifyListeners();
    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 900));
    // Create a placeholder friend entry (in production, loaded from Firestore)
    final newFriend = Friend(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed.split('@').first,
      email: trimmed,
      level: 1,
      totalXp: 0,
      streak: 0,
    );
    _friends.add(newFriend);
    _pendingRequest = null;
    _isLoading = false;
    notifyListeners();
    await _save();
    return null; // success
  }

  /// Removes [friend] from the friends list.
  Future<void> removeFriend(String id) async {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
    await _save();
  }

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
}
