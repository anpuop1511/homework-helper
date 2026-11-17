import 'assignment.dart';

/// A recurring assignment template, e.g. "Weekly Spanish vocab, every Monday".
///
/// A template spawns one [Assignment] (with [Assignment.templateId] set to
/// this template's [id]) on its [weekday].  Spawning is strict: it only
/// happens on the weekday itself, never as backfill for a missed day, so a
/// week the app was never opened does not dump a pile of overdue tasks.
/// [lastSpawnedDate] (date-only, local) records the last day an assignment
/// was spawned, which — together with the check for an existing spawned
/// assignment that day — makes spawning idempotent across restarts and
/// Firestore stream replays.
class AssignmentTemplate {
  final String id;
  final String title;
  final String subject;

  /// Weekday the template spawns on, using [DateTime] weekday numbers
  /// ([DateTime.monday] = 1 … [DateTime.sunday] = 7).
  final int weekday;

  /// Rough estimate of how long each spawned assignment takes, in minutes.
  /// Null when the user did not give one; copied onto spawned assignments.
  final int? estimatedMinutes;

  /// Date-only (local) day the template last spawned an assignment, or null
  /// if it never has.
  final DateTime? lastSpawnedDate;

  AssignmentTemplate({
    required this.id,
    required this.title,
    required this.subject,
    required this.weekday,
    this.estimatedMinutes,
    this.lastSpawnedDate,
  });

  AssignmentTemplate copyWith({
    String? id,
    String? title,
    String? subject,
    int? weekday,
    int? estimatedMinutes,
    DateTime? lastSpawnedDate,
  }) {
    return AssignmentTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      weekday: weekday ?? this.weekday,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      lastSpawnedDate: lastSpawnedDate ?? this.lastSpawnedDate,
    );
  }

  /// The next calendar date (date-only, local) this template spawns on,
  /// starting from [from] (defaults to today).  Includes today when today
  /// is the template's weekday.
  DateTime nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysAhead = (weekday - today.weekday + 7) % 7;
    return today.add(Duration(days: daysAhead));
  }

  /// Short weekday label, e.g. "Mon".
  String get weekdayLabel {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  /// Reads a template from a Firestore document map, with safe fallbacks
  /// for missing / malformed fields (same L-1 pattern as assignments).
  factory AssignmentTemplate.fromFirestore(
      String id, Map<String, dynamic> data) {
    final title = (data['title'] as String?) ?? 'Untitled';
    final rawWeekday = data['weekday'];
    final weekday = rawWeekday is int && rawWeekday >= DateTime.monday &&
            rawWeekday <= DateTime.sunday
        ? rawWeekday
        : DateTime.monday;
    final subjectRaw = data['subject'];
    final subject = subjectRaw is String &&
            Subject.allSubjects.contains(subjectRaw)
        ? subjectRaw
        : Subject.other;
    final estimated = data['estimatedMinutes'];
    final lastSpawnedMs = data['lastSpawnedDate'];
    return AssignmentTemplate(
      id: id,
      title: title,
      subject: subject,
      weekday: weekday,
      estimatedMinutes: estimated is int ? estimated : null,
      lastSpawnedDate: lastSpawnedMs is int
          ? DateTime.fromMillisecondsSinceEpoch(lastSpawnedMs)
          : null,
    );
  }

  /// Serialises the template for Firestore.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subject': subject,
        'weekday': weekday,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        if (lastSpawnedDate != null)
          'lastSpawnedDate': lastSpawnedDate!.millisecondsSinceEpoch,
      };

  @override
  String toString() =>
      'AssignmentTemplate(id: $id, title: $title, subject: $subject, '
      'weekday: $weekday, estimatedMinutes: $estimatedMinutes, '
      'lastSpawnedDate: $lastSpawnedDate)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssignmentTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
