/// Data models for the Social Quad feature.

/// Represents a friend in the user's social network.
class Friend {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? photoUrl;
  final int level;
  final int totalXp;
  final int streak;
  final String activeNameplate;
  /// Battle Pass type: 'free', 'plus', or 'premium'.
  final String passType;
  /// Currently equipped badge cosmetic ID.
  final String equippedBadge;

  const Friend({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.photoUrl,
    required this.level,
    required this.totalXp,
    required this.streak,
    this.activeNameplate = '',
    this.passType = 'free',
    this.equippedBadge = '',
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Display name shown in the Social Quad – @handle if available, otherwise name.
  /// Email is intentionally not exposed in public social views.
  String get displayHandle =>
      username.isNotEmpty ? '@$username' : (name.isNotEmpty ? name : 'Unknown user');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'level': level,
        'totalXp': totalXp,
        'streak': streak,
        if (activeNameplate.isNotEmpty) 'activeNameplate': activeNameplate,
        if (passType != 'free') 'passType': passType,
        if (equippedBadge.isNotEmpty) 'equippedBadge': equippedBadge,
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        level: json['level'] as int? ?? 1,
        totalXp: json['totalXp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        activeNameplate: json['activeNameplate'] as String? ?? '',
        passType: json['passType'] as String? ?? 'free',
        equippedBadge: json['equippedBadge'] as String? ?? '',
      );
}

/// Represents a pending incoming friend request.
class FriendRequest {
  final String id;
  final String fromUid;
  final String fromEmail;
  final String fromName;
  final String fromUsername;
  final String toUid;
  final DateTime timestamp;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromEmail,
    required this.fromName,
    this.fromUsername = '',
    required this.toUid,
    required this.timestamp,
  });
}

/// Represents an outgoing (sent) friend request that is still pending.
class SentRequest {
  final String id;
  final String toUid;
  final String toEmail;

  /// @username of the recipient if known, otherwise empty.
  final String toUsername;
  final DateTime timestamp;

  const SentRequest({
    required this.id,
    required this.toUid,
    required this.toEmail,
    this.toUsername = '',
    required this.timestamp,
  });

  /// Display label shown in the Pending tab – @handle if available, else email.
  String get displayHandle =>
      toUsername.isNotEmpty ? '@$toUsername' : toEmail;
}
