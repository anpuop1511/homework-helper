import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/assignment.dart';
import '../providers/assignments_provider.dart';
import '../widgets/assignment_card.dart';
import '../widgets/add_task_sheet.dart';
import 'subjects_screen.dart' show SubjectFolderSection;

/// The main dashboard screen featuring Material 3 Expressive design.
/// Displays a motivational header, subject filter chips, and assignment list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSubject = Subject.all;
  bool _showCompleted = false;

  // Sample motivational quotes for the daily motivation header
  static const List<String> _motivationQuotes = [
    '"The secret of getting ahead is getting started." — Mark Twain',
    '"It always seems impossible until it\'s done." — Nelson Mandela',
    '"Don\'t watch the clock; do what it does. Keep going." — Sam Levenson',
    '"Believe you can and you\'re halfway there." — Theodore Roosevelt',
    '"You don\'t have to be great to start, but you have to start to be great." — Zig Ziglar',
    '"Study while others are sleeping; work while others are loafing." — William A. Ward',
  ];

  String get _dailyQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _motivationQuotes[dayOfYear % _motivationQuotes.length];
  }

  List<Assignment> _filteredAssignments(List<Assignment> all) {
    return all.where((a) {
      final matchesSubject =
          _selectedSubject == Subject.all || a.subject == _selectedSubject;
      final matchesCompletion = _showCompleted || !a.isCompleted;
      return matchesSubject && matchesCompletion;
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  void _showAddAssignmentSheet() {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<AssignmentsProvider>();
    final filtered = _filteredAssignments(provider.assignments.toList());
    final pendingCount = provider.pendingCount;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Expressive App Bar with gradient header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _MotivationHeader(
                quote: _dailyQuote,
                pendingCount: pendingCount,
                colorScheme: colorScheme,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showCompleted
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _showCompleted
                    ? 'Hide completed'
                    : 'Show completed',
                onPressed: () =>
                    setState(() => _showCompleted = !_showCompleted),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Subject Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Subject',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: Subject.allSubjects.map((subject) {
                        final isSelected = _selectedSubject == subject;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(subject),
                            selected: isSelected,
                            onSelected: (_) => setState(
                                () => _selectedSubject = subject),
                            showCheckmark: false,
                            avatar: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Assignments header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assignments',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${filtered.length} task${filtered.length != 1 ? 's' : ''}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Assignment list or empty state
          filtered.isEmpty
              ? SliverToBoxAdapter(child: _EmptyState(colorScheme: colorScheme))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final assignment = filtered[index];
                        return AssignmentCard(
                          assignment: assignment,
                          onToggleComplete: () =>
                              context.read<AssignmentsProvider>().toggleComplete(assignment.id),
                          onDelete: () => context.read<AssignmentsProvider>().delete(assignment.id),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

          // Subject Folders section embedded in Home
          SliverToBoxAdapter(
            child: SubjectFolderSection(colorScheme: colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssignmentSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

/// The motivational header shown at the top of the dashboard.
class _MotivationHeader extends StatelessWidget {
  final String quote;
  final int pendingCount;
  final ColorScheme colorScheme;

  const _MotivationHeader({
    required this.quote,
    required this.pendingCount,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 14,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Hey there! 👋',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                pendingCount == 0
                    ? 'All caught up for today! 🎉'
                    : '$pendingCount assignment${pendingCount != 1 ? 's' : ''} pending',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onPrimaryContainer.withAlpha(204),
                ),
              ),
              const SizedBox(height: 12),
              // Daily Motivation Quote
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(153),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when there are no assignments matching the current filter.
class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No assignments here!',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add a new task.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


