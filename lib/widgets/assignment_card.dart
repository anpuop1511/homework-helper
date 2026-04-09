import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';

/// A styled card widget for displaying a single assignment.
/// Uses Material 3 Expressive design with elevation: 0 and subtle borders.
class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOverdue = !assignment.isCompleted &&
        assignment.dueDate.isBefore(DateTime.now());
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggleComplete,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion checkbox with animated styling
              GestureDetector(
                onTap: onToggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: assignment.isCompleted
                        ? colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: assignment.isCompleted
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: assignment.isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Assignment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      assignment.title,
                      style: textTheme.titleMedium?.copyWith(
                        decoration: assignment.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: assignment.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subject chip and due date row
                    Row(
                      children: [
                        _SubjectBadge(
                          subject: assignment.subject,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: isOverdue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(assignment.dueDate),
                          style: textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Days remaining or overdue indicator
                    if (!assignment.isCompleted) ...[
                      const SizedBox(height: 4),
                      _DueDateBadge(
                        daysLeft: daysLeft,
                        isOverdue: isOverdue,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small colored badge showing the assignment subject.
class _SubjectBadge extends StatelessWidget {
  final String subject;
  final ColorScheme colorScheme;

  const _SubjectBadge({required this.subject, required this.colorScheme});

  Color _getSubjectColor() {
    switch (subject) {
      case 'Math':
        return const Color(0xFF1565C0);
      case 'Science':
        return const Color(0xFF2E7D32);
      case 'History':
        return const Color(0xFF6A1B9A);
      case 'English':
        return const Color(0xFFE65100);
      case 'Art':
        return const Color(0xFFC62828);
      case 'Music':
        return const Color(0xFF00695C);
      case 'P.E.':
        return const Color(0xFF4527A0);
      default:
        return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _getSubjectColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: subjectColor.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: subjectColor.withAlpha(77), width: 1),
      ),
      child: Text(
        subject,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: subjectColor,
        ),
      ),
    );
  }
}

/// Shows how many days remain until the assignment is due.
class _DueDateBadge extends StatelessWidget {
  final int daysLeft;
  final bool isOverdue;
  final ColorScheme colorScheme;

  const _DueDateBadge({
    required this.daysLeft,
    required this.isOverdue,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (isOverdue) {
      return Text(
        'Overdue!',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.error,
        ),
      );
    } else if (daysLeft == 0) {
      return Text(
        'Due today',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.tertiary,
        ),
      );
    } else if (daysLeft == 1) {
      return Text(
        'Due tomorrow',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.tertiary,
        ),
      );
    } else {
      return Text(
        '$daysLeft days left',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
  }
}
