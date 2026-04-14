import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/assignment.dart';
import '../providers/assignments_provider.dart';
import '../providers/subjects_provider.dart';
import '../widgets/assignment_card.dart';
import '../widgets/add_task_sheet.dart';

/// Displays assignments grouped into expressive subject-folder sections.
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final assignments =
        context.watch<AssignmentsProvider>().assignments.toList();

    // Build a map of subject → assignments (excluding 'All')
    final Map<String, List<Assignment>> grouped = {};
    for (final subject in Subject.allSubjects) {
      if (subject == Subject.all) continue;
      final list = assignments.where((a) => a.subject == subject).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (list.isNotEmpty) {
        grouped[subject] = list;
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Subject Folders'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: grouped.isEmpty
          ? _EmptyFolders(colorScheme: colorScheme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: grouped.entries.map((entry) {
                return _SubjectFolder(
                  subject: entry.key,
                  assignments: entry.value,
                  colorScheme: colorScheme,
                  textTheme: Theme.of(context).textTheme,
                );
              }).toList(),
            ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddTaskSheet(),
    );
  }
}

/// Inline subject folders widget embedded in [HomeScreen].
///
/// Shows a collapsible "Subject Folders" header followed by individual
/// subject folder cards for each subject that has at least one assignment.
class SubjectFolderSection extends StatefulWidget {
  final ColorScheme colorScheme;

  const SubjectFolderSection({super.key, required this.colorScheme});

  @override
  State<SubjectFolderSection> createState() => _SubjectFolderSectionState();
}

class _SubjectFolderSectionState extends State<SubjectFolderSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final assignments =
        context.watch<AssignmentsProvider>().assignments.toList();

    final Map<String, List<Assignment>> grouped = {};
    for (final subject in Subject.allSubjects) {
      if (subject == Subject.all) continue;
      final list = assignments.where((a) => a.subject == subject).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (list.isNotEmpty) {
        grouped[subject] = list;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'Subject Folders',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: grouped.isEmpty
                ? _EmptyFolders(colorScheme: widget.colorScheme)
                : Column(
                    children: grouped.entries.map((entry) {
                      return _SubjectFolder(
                        subject: entry.key,
                        assignments: entry.value,
                        colorScheme: widget.colorScheme,
                        textTheme: textTheme,
                      );
                    }).toList(),
                  ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

/// An expandable folder section for a single subject.
class _SubjectFolder extends StatefulWidget {
  final String subject;
  final List<Assignment> assignments;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SubjectFolder({
    required this.subject,
    required this.assignments,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  State<_SubjectFolder> createState() => _SubjectFolderState();
}

class _SubjectFolderState extends State<_SubjectFolder>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Color _subjectColor() {
    switch (widget.subject) {
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

  IconData _subjectIcon() {
    switch (widget.subject) {
      case 'Math':
        return Icons.calculate_outlined;
      case 'Science':
        return Icons.science_outlined;
      case 'History':
        return Icons.history_edu_outlined;
      case 'English':
        return Icons.menu_book_outlined;
      case 'Art':
        return Icons.palette_outlined;
      case 'Music':
        return Icons.music_note_outlined;
      case 'P.E.':
        return Icons.sports_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor();
    final pending =
        widget.assignments.where((a) => !a.isCompleted).length;
    final provider = context.read<AssignmentsProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Folder header
          InkWell(
            onTap: _toggle,
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_subjectIcon(), color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.watch<SubjectsProvider>().displayName(widget.subject),
                          style: widget.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$pending pending · '
                          '${widget.assignments.length} total',
                          style: widget.textTheme.bodySmall?.copyWith(
                            color: widget.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress ring
                  _ProgressRing(
                    completed: widget.assignments.length - pending,
                    total: widget.assignments.length,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded assignment list
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: widget.colorScheme.outlineVariant,
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Column(
                    children: widget.assignments.map((assignment) {
                      return AssignmentCard(
                        assignment: assignment,
                        onToggleComplete: () =>
                            provider.toggleComplete(assignment.id),
                        onDelete: () =>
                            provider.delete(assignment.id),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small circular progress ring showing completion ratio.
class _ProgressRing extends StatelessWidget {
  final int completed;
  final int total;
  final Color color;

  const _ProgressRing({
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.5,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$completed/$total',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when there are no assignments yet.
class _EmptyFolders extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyFolders({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No subjects yet!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add assignments from the Home tab and they will appear here grouped by subject.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
