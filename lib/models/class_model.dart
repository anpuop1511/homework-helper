import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a persistent class/course that a student is enrolled in.
///
/// Classes are stored under `users/{uid}/classes/{classId}` in Firestore.
/// Subjects are stored as an array field on the class document for simplicity.
class SchoolClass {
  /// Firestore document ID (empty string before the document is saved).
  final String id;

  /// Display name of the class (e.g. "AP Biology", "Calculus BC").
  final String name;

  /// Optional description or teacher name.
  final String description;

  /// List of subject names associated with this class.
  final List<String> subjects;

  /// Optional Google Classroom invite/class URL.
  final String? googleClassroomUrl;

  const SchoolClass({
    required this.id,
    required this.name,
    this.description = '',
    this.subjects = const [],
    this.googleClassroomUrl,
  });

  SchoolClass copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? subjects,
    String? googleClassroomUrl,
    bool clearClassroomUrl = false,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      googleClassroomUrl: clearClassroomUrl
          ? null
          : (googleClassroomUrl ?? this.googleClassroomUrl),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'subjects': subjects,
        'googleClassroomUrl': googleClassroomUrl,
      };

  factory SchoolClass.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SchoolClass(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      subjects: List<String>.from(data['subjects'] as List? ?? []),
      googleClassroomUrl: data['googleClassroomUrl'] as String?,
    );
  }
}
