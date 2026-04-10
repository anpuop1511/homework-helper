/// Data models for the Social Quad feature.

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
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        totalXp: json['totalXp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
      );
}

/// Represents a pending incoming friend request.
class FriendRequest {
  final String id;
  final String fromUid;
  final String fromEmail;
  final String fromName;
  final String toUid;
  final DateTime timestamp;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromEmail,
    required this.fromName,
    required this.toUid,
    required this.timestamp,
  });
}
