import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/assignment_template.dart';
import '../utils/due_date.dart' as due;

/// Home-screen summary cards for the December feature drop:
///   - [DueCountdownCard]: countdown to the nearest due assignment.
///   - [TonightsWorkloadCard]: what is due tonight / tomorrow + time estimate.
///   - [RecurringTemplatesCard]: active weekly templates, with delete.
///
/// All three share the Command Center card styling (surfaceContainerLow,
/// 24px radius, outline border).  They take plain data as parameters and
/// hold no provider reads, so they stay usable anywhere assignments exist.

/// Countdown to the nearest pending assignment, e.g. "due in 2d 4h".
/// Ticks once a minute so the countdown stays fresh while Home is open.
/// Overdue work reads "Overdue by 1d 3h" in the error colour; with nothing
/// pending it shows an "All caught up" state instead of disappearing.
class DueCountdownCard extends StatefulWidget {
  final List<Assignment> assignments;

  const DueCountdownCard({super.key, required this.assignments});

  @override
  State<DueCountdownCard> createState() => _DueCountdownCardState();
}

class _DueCountdownCardState extends State<DueCountdownCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild once a minute so "due in 5h 12m" keeps counting down.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final pending =
        widget.assignments.where((a) => !a.isCompleted).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final next = pending.isEmpty ? null : pending.first;
    final overdue =
        next != null && due.isOverdue(next.dueDate, now);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: overdue
              ? colorScheme.error.withAlpha(120)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: overdue
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              overdue ? Icons.alarm_off_rounded : Icons.hourglass_top_rounded,
              color: overdue
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null ? 'All caught up 🎉' : next.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next == null
                      ? 'Nothing due — enjoy the free evening.'
                      : '${due.formatCountdown(next.dueDate, now)}'
                          ' • ${next.subject} • '
                          '${DateFormat('EEE, MMM d').format(next.dueDate)}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: overdue
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (pending.length > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${pending.length - 1} more',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Tonight's workload": how much is due tonight (today + overdue) and
/// tomorrow, the estimated time for tonight's work, and up to three of
/// tonight's assignments.  The estimate only totals assignments that have
/// one — when none do, the card says so instead of inventing a number.
class TonightsWorkloadCard extends StatelessWidget {
  final List<Assignment> assignments;

  const TonightsWorkloadCard({super.key, required this.assignments});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final summary = due.summarizeWorkload(assignments, now);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round,
                  color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Tonight's workload",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (summary.overdueCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.overdueCount} overdue',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WorkloadStat(
                value: '${summary.tonight.length}',
                label: 'due tonight',
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _WorkloadStat(
                value: '${summary.tomorrow.length}',
                label: 'due tomorrow',
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _WorkloadStat(
                value: summary.hasAnyEstimate
                    ? '≈ ${due.formatEstimatedMinutes(summary.estimatedMinutes)}'
                    : '—',
                label: summary.hasAnyEstimate
                    ? 'estimated'
                    : 'no time estimates yet',
                colorScheme: colorScheme,
              ),
            ],
          ),
          if (summary.tonight.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...summary.tonight.take(3).map((a) {
              final isOver = due.isOverdue(a.dueDate, now);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      isOver
                          ? Icons.error_outline_rounded
                          : Icons.circle_outlined,
                      size: 16,
                      color: isOver
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      due.formatCountdown(a.dueDate, now),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOver
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (summary.tonight.isEmpty && summary.tomorrow.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nothing due tonight or tomorrow. 🎉',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkloadStat extends StatelessWidget {
  final String value;
  final String label;
  final ColorScheme colorScheme;

  const _WorkloadStat({
    required this.value,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active recurring assignment templates ("Every Monday"), with a delete
/// button per template.  Deleting a template never deletes assignments it
/// already spawned.  Only rendered when there is at least one template.
class RecurringTemplatesCard extends StatelessWidget {
  final List<AssignmentTemplate> templates;
  final void Function(String templateId) onDelete;

  const RecurringTemplatesCard({
    super.key,
    required this.templates,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded,
                  color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Repeating assignments',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...templates.map((t) {
            final next = t.nextOccurrence();
            final isToday = due.dateOnly(next) == due.dateOnly(DateTime.now());
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                t.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Every ${t.weekdayLabel} • ${t.subject}'
                '${t.estimatedMinutes != null
                    ? ' • ≈ ${due.formatEstimatedMinutes(t.estimatedMinutes!)}'
                    : ''}'
                ' • Next: ${isToday ? 'today' : DateFormat('EEE, MMM d').format(next)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete repeating assignment',
                onPressed: () => onDelete(t.id),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
