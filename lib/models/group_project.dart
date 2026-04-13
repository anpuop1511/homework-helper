import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a collaborative Group Project in Social Quad.
///
/// Projects are stored in the global `projects/{projectId}` collection.
/// Subcollections:
///   - `projects/{projectId}/bulletins` – bulletin board posts
///   - `projects/{projectId}/tasks`     – split tasks with assignee + status
class GroupProject {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String ownerUid;
  final List<String> memberUids;

  const GroupProject({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.ownerUid,
    required this.memberUids,
  });

  GroupProject copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? ownerUid,
    List<String>? memberUids,
  }) =>
      GroupProject(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        ownerUid: ownerUid ?? this.ownerUid,
        memberUids: memberUids ?? this.memberUids,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'ownerUid': ownerUid,
        'memberUids': memberUids,
      };

  factory GroupProject.fromJson(String id, Map<String, dynamic> json) =>
      GroupProject(
        id: id,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ownerUid: json['ownerUid'] as String? ?? '',
        memberUids: List<String>.from(json['memberUids'] as List? ?? []),
      );
}

/// A post on a project's bulletin board.
class BulletinPost {
  final String id;
  final String authorUid;
  final String authorUsername;
  final String text;
  final DateTime createdAt;

  const BulletinPost({
    required this.id,
    required this.authorUid,
    required this.authorUsername,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'authorUid': authorUid,
        'authorUsername': authorUsername,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory BulletinPost.fromJson(String id, Map<String, dynamic> json) =>
      BulletinPost(
        id: id,
        authorUid: json['authorUid'] as String? ?? '',
        authorUsername: json['authorUsername'] as String? ??
            json['authorHandle'] as String? ??
            '',
        text: json['text'] as String? ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// A task within a project that can be assigned to a member.
class ProjectTask {
  final String id;
  final String title;
  final String assigneeUid;
  final TaskStatus status;
  final DateTime createdAt;

  const ProjectTask({
    required this.id,
    required this.title,
    this.assigneeUid = '',
    this.status = TaskStatus.todo,
    required this.createdAt,
  });

  ProjectTask copyWith({
    String? id,
    String? title,
    String? assigneeUid,
    TaskStatus? status,
    DateTime? createdAt,
  }) =>
      ProjectTask(
        id: id ?? this.id,
        title: title ?? this.title,
        assigneeUid: assigneeUid ?? this.assigneeUid,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'assigneeUid': assigneeUid,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ProjectTask.fromJson(String id, Map<String, dynamic> json) =>
      ProjectTask(
        id: id,
        title: json['title'] as String? ?? '',
        assigneeUid: json['assigneeUid'] as String? ?? '',
        status: TaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TaskStatus.todo,
        ),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

enum TaskStatus { todo, inProgress, done }

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}
