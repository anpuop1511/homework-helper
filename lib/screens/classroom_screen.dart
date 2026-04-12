import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/classroom_provider.dart';

/// Google Classroom integration screen.
///
/// Reached from Settings → Integrations → Google Classroom.
///
/// Allows the user to:
/// - Authorize Classroom access via Google OAuth (Classroom scopes only).
/// - Browse their active courses.
/// - Browse coursework for a selected course.
/// - Disconnect / revoke access.
///
/// This screen does **not** affect the main Firebase email/password auth.
class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final classroom = context.watch<ClassroomProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Google Classroom',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (classroom.isAuthorized)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh courses',
              onPressed: classroom.coursesLoading
                  ? null
                  : () => classroom.fetchCourses(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, classroom, colorScheme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClassroomProvider classroom,
    ColorScheme colorScheme,
  ) {
    switch (classroom.status) {
      case ClassroomAuthStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ClassroomAuthStatus.notAuthorized:
        return _NotAuthorizedView(colorScheme: colorScheme);

      case ClassroomAuthStatus.authorizing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to Google Classroom…'),
            ],
          ),
        );

      case ClassroomAuthStatus.authorized:
        return _AuthorizedView(colorScheme: colorScheme);

      case ClassroomAuthStatus.error:
        return _ErrorView(colorScheme: colorScheme);
    }
  }
}

// ── Not-authorized view ───────────────────────────────────────────────────

class _NotAuthorizedView extends StatelessWidget {
  final ColorScheme colorScheme;
  const _NotAuthorizedView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final classroom = context.read<ClassroomProvider>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Hero icon
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 48,
              color: Color(0xFF1A73E8),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Connect Google Classroom',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Link your Google Classroom account to browse your courses and coursework directly in Homework Helper.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        // Scopes granted
        _InfoCard(
          colorScheme: colorScheme,
          icon: Icons.lock_outline_rounded,
          title: 'What access is requested',
          body:
              '• Read your courses (read-only)\n'
              '• Read your coursework (read-only)\n'
              '• Read your assignment submissions (read-only)\n\n'
              'No data is modified. Access can be revoked at any time.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => classroom.authorize(),
            icon: const Icon(Icons.school_rounded),
            label: Text(
              'Authorize Google Classroom',
              style: GoogleFonts.lexend(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You will be redirected to Google to grant access. '
          'Your existing Homework Helper login is not changed.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ErrorView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final classroom = context.watch<ClassroomProvider>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Connection Error',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (classroom.error != null)
          Text(
            classroom.error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        // Debug-only: show raw exception details to assist configuration
        // troubleshooting. Never visible in release/profile builds.
        if (kDebugMode && classroom.diagnosticDetail != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report_rounded,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Debug diagnostics',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  classroom.diagnosticDetail!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => classroom.authorize(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Try Again',
              style: GoogleFonts.lexend(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => classroom.disconnect(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Disconnect',
              style: GoogleFonts.lexend(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Authorized view ───────────────────────────────────────────────────────

class _AuthorizedView extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AuthorizedView({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final classroom = context.watch<ClassroomProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Status card
        _ConnectedStatusCard(colorScheme: colorScheme),
        const SizedBox(height: 16),
        // Error banner (non-fatal, e.g. fetch failed but still authorized)
        if (classroom.error != null && !classroom.coursesLoading) ...[
          _ErrorBanner(error: classroom.error!, colorScheme: colorScheme),
          const SizedBox(height: 12),
        ],
        // Courses section
        _SectionHeader(
          colorScheme: colorScheme,
          title: 'Active Courses',
          trailing: classroom.coursesLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: 8),
        if (classroom.coursesLoading && classroom.courses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (classroom.courses.isEmpty && !classroom.coursesLoading)
          _EmptyState(
            colorScheme: colorScheme,
            icon: Icons.class_rounded,
            message: 'No active courses found.',
          )
        else ...[
          ...classroom.courses
              .map((c) => _CourseCard(course: c, colorScheme: colorScheme)),
        ],
        const SizedBox(height: 16),
        // Coursework section (shown when a course is selected)
        if (classroom.selectedCourseId != null) ...[
          _SectionHeader(
            colorScheme: colorScheme,
            title: 'Coursework',
            trailing: classroom.courseworkLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          if (classroom.courseworkLoading && classroom.coursework.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (classroom.coursework.isEmpty && !classroom.courseworkLoading)
            _EmptyState(
              colorScheme: colorScheme,
              icon: Icons.assignment_rounded,
              message: 'No coursework found for this course.',
            )
          else ...[
            ...classroom.coursework.map(
              (cw) => _CourseworkCard(coursework: cw, colorScheme: colorScheme),
            ),
          ],
          const SizedBox(height: 16),
        ],
        // Disconnect button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDisconnect(context, classroom),
            icon: Icon(Icons.link_off_rounded, color: colorScheme.error),
            label: Text(
              'Disconnect Google Classroom',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _confirmDisconnect(
      BuildContext context, ClassroomProvider classroom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Disconnect Classroom?'),
        content: const Text(
          'This will revoke Homework Helper\'s access to your Google Classroom. '
          'You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await classroom.disconnect();
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _ConnectedStatusCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ConnectedStatusCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A73E8).withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF1A73E8),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Classroom Connected',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Read-only access to your courses and coursework.',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF1A73E8), size: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  final String title;
  final Widget? trailing;
  const _SectionHeader(
      {required this.colorScheme, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final ClassroomCourse course;
  final ColorScheme colorScheme;
  const _CourseCard({required this.course, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final classroom = context.read<ClassroomProvider>();
    final isSelected = classroom.selectedCourseId == course.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => classroom.fetchCoursework(courseId: course.id),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withAlpha(30)
                        : const Color(0xFF1A73E8).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_rounded,
                    color: isSelected
                        ? colorScheme.primary
                        : const Color(0xFF1A73E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (course.section != null && course.section!.isNotEmpty)
                        Text(
                          course.section!,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseworkCard extends StatelessWidget {
  final ClassroomCoursework coursework;
  final ColorScheme colorScheme;
  const _CourseworkCard(
      {required this.coursework, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _workTypeIcon(coursework.workType),
                color: colorScheme.onSecondaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coursework.title,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (coursework.dueDateLabel != null)
                    Text(
                      'Due: ${coursework.dueDateLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (coursework.workType != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _workTypeLabel(coursework.workType),
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _workTypeIcon(String? type) {
    switch (type) {
      case 'ASSIGNMENT':
        return Icons.assignment_rounded;
      case 'SHORT_ANSWER_QUESTION':
      case 'MULTIPLE_CHOICE_QUESTION':
        return Icons.quiz_rounded;
      case 'MATERIAL':
        return Icons.article_rounded;
      default:
        return Icons.task_rounded;
    }
  }

  String _workTypeLabel(String? type) {
    switch (type) {
      case 'ASSIGNMENT':
        return 'Assignment';
      case 'SHORT_ANSWER_QUESTION':
        return 'Short Answer';
      case 'MULTIPLE_CHOICE_QUESTION':
        return 'MCQ';
      case 'MATERIAL':
        return 'Material';
      default:
        return 'Task';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String message;
  const _EmptyState(
      {required this.colorScheme,
      required this.icon,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final ColorScheme colorScheme;
  const _ErrorBanner({required this.error, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded,
              color: colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
