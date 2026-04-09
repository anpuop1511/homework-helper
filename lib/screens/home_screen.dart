import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../widgets/assignment_card.dart';

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

  // Assignment state managed with StatefulWidget
  final List<Assignment> _assignments = [
    Assignment(
      id: '1',
      title: 'Chapter 5 Algebra Problems',
      subject: Subject.math,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Assignment(
      id: '2',
      title: 'Lab Report: Chemical Reactions',
      subject: Subject.science,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    Assignment(
      id: '3',
      title: 'Essay: World War II Causes',
      subject: Subject.history,
      dueDate: DateTime.now().add(const Duration(days: 5)),
    ),
    Assignment(
      id: '4',
      title: 'Shakespeare: Romeo & Juliet Analysis',
      subject: Subject.english,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Assignment(
      id: '5',
      title: 'Watercolor Landscape Painting',
      subject: Subject.art,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ),
    Assignment(
      id: '6',
      title: 'Practice Scales — C Major',
      subject: Subject.music,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      isCompleted: true,
    ),
  ];

  List<Assignment> get _filteredAssignments {
    return _assignments.where((a) {
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

  int get _pendingCount =>
      _assignments.where((a) => !a.isCompleted).length;

  void _toggleAssignment(String id) {
    setState(() {
      final idx = _assignments.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _assignments[idx].isCompleted = !_assignments[idx].isCompleted;
      }
    });
  }

  void _deleteAssignment(String id) {
    setState(() {
      _assignments.removeWhere((a) => a.id == id);
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
      builder: (ctx) => _AddAssignmentSheet(
        onAdd: (assignment) {
          setState(() {
            _assignments.add(assignment);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filteredAssignments;

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
                pendingCount: _pendingCount,
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final assignment = filtered[index];
                        return AssignmentCard(
                          assignment: assignment,
                          onToggleComplete: () =>
                              _toggleAssignment(assignment.id),
                          onDelete: () => _deleteAssignment(assignment.id),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
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

/// Bottom sheet for adding a new assignment.
class _AddAssignmentSheet extends StatefulWidget {
  final void Function(Assignment) onAdd;

  const _AddAssignmentSheet({required this.onAdd});

  @override
  State<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<_AddAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _selectedSubject = Subject.math;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final assignment = Assignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        subject: _selectedSubject,
        dueDate: _dueDate,
      );
      widget.onAdd(assignment);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Assignment',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                hintText: 'e.g. Chapter 3 Reading',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            // Subject dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              borderRadius: BorderRadius.circular(16),
              items: Subject.allSubjects
                  .where((s) => s != Subject.all)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedSubject = v);
              },
            ),
            const SizedBox(height: 16),
            // Due date picker
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Due: ${DateFormat('EEEE, MMMM d').format(_dueDate)}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Add Assignment'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
