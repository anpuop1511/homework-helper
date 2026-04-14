/// Represents a homework assignment with all relevant metadata.
class Assignment {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  bool isCompleted;

  /// True once the XP/Coin/SeasonXP rewards have been claimed for this
  /// assignment.  Prevents farming by toggling completion repeatedly.
  bool rewardsClaimed;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.rewardsClaimed = false,
  });

  /// Creates a copy of this assignment with updated fields.
  Assignment copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    bool? isCompleted,
    bool? rewardsClaimed,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }

  @override
  String toString() {
    return 'Assignment(id: $id, title: $title, subject: $subject, '
        'dueDate: $dueDate, isCompleted: $isCompleted, '
        'rewardsClaimed: $rewardsClaimed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Subject categories available for assignments.
class Subject {
  static const String all = 'All';
  static const String math = 'Math';
  static const String science = 'Science';
  static const String history = 'History';
  static const String english = 'English';
  static const String art = 'Art';
  static const String music = 'Music';
  static const String pe = 'P.E.';
  static const String other = 'Other';

  static const List<String> allSubjects = [
    all,
    math,
    science,
    history,
    english,
    art,
    music,
    pe,
    other,
  ];
}
