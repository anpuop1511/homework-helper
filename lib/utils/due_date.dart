import '../models/assignment.dart';

/// Pure date/countdown helpers shared by the Home summary cards and the
/// recurring-template spawn logic.  No Flutter imports — plain Dart, so the
/// behaviour is the same everywhere it is used.
///
/// Due dates in this app are date-only (midnight, local), picked with
/// [showDatePicker].  Everything here therefore treats a due date as
/// "due by the end of that calendar day" ([endOfDueDay]), not "due at
/// midnight when the day starts" — otherwise a task due today would read as
/// overdue at 00:01.

/// The date-only (midnight, local) form of [dt].
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// End of the due day: 23:59 on the due date's calendar day (local).
DateTime endOfDueDay(DateTime dueDate) {
  final d = dateOnly(dueDate);
  return DateTime(d.year, d.month, d.day, 23, 59);
}

/// True when [now] is past the end of [dueDate]'s day.
bool isOverdue(DateTime dueDate, DateTime now) =>
    now.isAfter(endOfDueDay(dueDate));

/// True when [dueDate] falls on [day]'s calendar day (local).
bool isDueOn(DateTime dueDate, DateTime day) =>
    dateOnly(dueDate) == dateOnly(day);

/// Human countdown to [dueDate] from [now], e.g. "due in 2d 4h",
/// "due in 5h 12m", "due in 32m", or "Overdue by 1d 3h" once the due day
/// has ended.
String formatCountdown(DateTime dueDate, DateTime now) {
  final end = endOfDueDay(dueDate);
  if (now.isAfter(end)) {
    final over = now.difference(end);
    if (over.inDays >= 1) {
      return 'Overdue by ${over.inDays}d ${over.inHours % 24}h';
    }
    if (over.inHours >= 1) {
      return 'Overdue by ${over.inHours}h ${over.inMinutes % 60}m';
    }
    return 'Overdue by ${over.inMinutes}m';
  }
  final remaining = end.difference(now);
  if (remaining.inDays >= 1) {
    return 'due in ${remaining.inDays}d ${remaining.inHours % 24}h';
  }
  if (remaining.inHours >= 1) {
    return 'due in ${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }
  if (remaining.inMinutes >= 1) {
    return 'due in ${remaining.inMinutes}m';
  }
  return 'due now';
}

/// Formats an estimate in minutes as "45m", "1h" or "1h 30m".
String formatEstimatedMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

/// Summary of what is due tonight / tomorrow, for the Home workload card.
class WorkloadSummary {
  /// Pending assignments due today or already overdue — tonight's work.
  /// Overdue items come first, then today's, each by due date.
  final List<Assignment> tonight;

  /// Pending assignments due tomorrow.
  final List<Assignment> tomorrow;

  /// How many of [tonight] are already overdue.
  final int overdueCount;

  /// Sum of [Assignment.estimatedMinutes] across [tonight], counting only
  /// assignments that actually have an estimate.
  final int estimatedMinutes;

  /// True when at least one of [tonight] carries a time estimate.
  final bool hasAnyEstimate;

  const WorkloadSummary({
    required this.tonight,
    required this.tomorrow,
    required this.overdueCount,
    required this.estimatedMinutes,
    required this.hasAnyEstimate,
  });
}

/// Partitions pending (not completed) assignments into tonight / tomorrow
/// buckets as of [now] (local).  "Tonight" = due today or overdue.
WorkloadSummary summarizeWorkload(
    List<Assignment> assignments, DateTime now) {
  final today = dateOnly(now);
  final tomorrowDate = today.add(const Duration(days: 1));
  final pending = assignments.where((a) => !a.isCompleted).toList();
  final tonight = pending
      .where((a) =>
          isOverdue(a.dueDate, now) || isDueOn(a.dueDate, today))
      .toList()
    ..sort((a, b) {
      final aOver = isOverdue(a.dueDate, now);
      final bOver = isOverdue(b.dueDate, now);
      if (aOver != bOver) return aOver ? -1 : 1;
      return a.dueDate.compareTo(b.dueDate);
    });
  final tomorrow = pending
      .where((a) => isDueOn(a.dueDate, tomorrowDate))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  var estimated = 0;
  var hasAny = false;
  for (final a in tonight) {
    final mins = a.estimatedMinutes;
    if (mins != null) {
      estimated += mins;
      hasAny = true;
    }
  }
  return WorkloadSummary(
    tonight: tonight,
    tomorrow: tomorrow,
    overdueCount: tonight.where((a) => isOverdue(a.dueDate, now)).length,
    estimatedMinutes: estimated,
    hasAnyEstimate: hasAny,
  );
}
