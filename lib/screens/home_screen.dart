import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/season_live_ops.dart';
import '../config/secrets.dart';
import '../models/assignment.dart';
import '../models/class_model.dart';
import '../providers/assignments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/classes_provider.dart';
import '../providers/dev_clock_provider.dart';
import '../providers/entitlements_provider.dart';
import '../providers/event_provider.dart';
import '../providers/subjects_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/assignment_card.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/gradient_text.dart';
import 'ladder_event_screen.dart';
import 'subjects_screen.dart' show SubjectFolderSection;
import 'settings_screen.dart';
import 'chat_screen.dart';

/// The main dashboard screen featuring Material 3 Expressive design.
/// Displays a motivational header, subject filter chips, and assignment list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Logical pixels of downward pull needed at top of Home before opening buddy.
  static const double _studyBuddyPullThresholdPixels = 74;
  static const double _expandedHeaderHeight = 248;

  String _selectedSubject = Subject.all;
  bool _showCompleted = false;
  bool _isStudyBuddySheetOpen = false;
  double _pullDistance = 0;

  // Sample motivational quotes for the daily motivation header
  static const List<String> _motivationQuotes = [
    '"The secret of getting ahead is getting started." — Mark Twain',
    '"It always seems impossible until it\'s done." — Nelson Mandela',
    '"Don\'t watch the clock; do what it does. Keep going." — Sam Levenson',
    '"Believe you can and you\'re halfway there." — Theodore Roosevelt',
    '"You don\'t have to be great to start, but you have to start to be great." — Zig Ziglar',
    '"Study while others are sleeping; work while others are loafing." — William A. Ward',
  ];

  String _dailyQuoteFor(DateTime now) {
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
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

  /// Returns a time-based greeting word based on the given datetime.
  ///
  /// [now] is expected to be in UTC (from [DevClockProvider.nowUtc]).  The
  /// hour is read in local time so the greeting matches what the user sees.
  static String _timeGreeting(DateTime now) {
    final hour = now.toLocal().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Hello';
  }

  /// Resolves the best display name for the greeting, using the fallback order:
  /// 1. FirebaseAuth displayName (trimmed, non-empty)
  /// 2. App username/handle prefixed with '@'
  /// 3. Email prefix before '@'
  /// 4. "there"
  static String _resolveGreetingName(AuthProvider auth, UserProvider user) {
    final firebaseName = auth.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;
    final username = auth.username;
    if (username != null && username.isNotEmpty) return '@$username';
    final email = auth.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'there';
  }

  bool _onHomeScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        notification.metrics.extentBefore == 0) {
      _pullDistance = 0;
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.metrics.extentBefore == 0 &&
        notification.overscroll < 0) {
      _pullDistance += notification.overscroll.abs();
      _maybeOpenStudyBuddy();
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.metrics.extentBefore == 0 &&
        notification.dragDetails != null) {
      final dragDelta = notification.dragDetails!.delta.dy;
      if (dragDelta > 0) {
        _pullDistance += dragDelta;
        _maybeOpenStudyBuddy();
      } else if (dragDelta < 0) {
        _pullDistance = 0;
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      _pullDistance = 0;
      return false;
    }

    return false;
  }

  void _maybeOpenStudyBuddy() {
    if (_isStudyBuddySheetOpen ||
        _pullDistance < _studyBuddyPullThresholdPixels) {
      return;
    }
    _pullDistance = 0;
    _openStudyBuddyTopSheet();
  }

  Future<void> _openStudyBuddyTopSheet() async {
    _isStudyBuddySheetOpen = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierLabel: 'AI Study Buddy',
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(80),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const _StudyBuddyTopSheet(),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      _isStudyBuddySheetOpen = false;
      _pullDistance = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<AssignmentsProvider>();
    final auth = context.watch<AuthProvider>();
    final user = context.watch<UserProvider>();
    final effectiveNow = context.watch<DevClockProvider>().nowUtc();
    final filtered = _filteredAssignments(provider.assignments.toList());
    final pendingCount = provider.pendingCount;
    final greeting =
        '${_timeGreeting(effectiveNow)}, ${_resolveGreetingName(auth, user)}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onHomeScroll,
        child: CustomScrollView(
          slivers: [
          // Expressive App Bar with gradient header
          SliverAppBar(
            expandedHeight: _expandedHeaderHeight,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _MotivationHeader(
                quote: _dailyQuoteFor(effectiveNow),
                pendingCount: pendingCount,
                colorScheme: colorScheme,
                greeting: greeting,
              ),
            ),
            actions: [
              Consumer<UserProvider>(
                builder: (context, user, _) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(140),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${user.coins}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

          // ── Classes Section ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ClassesSection(colorScheme: colorScheme),
          ),

          // ── Event Banner ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _EventBannerCard(colorScheme: colorScheme),
          ),

          // Command center: filters + quick status
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
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
                        Icon(Icons.space_dashboard_rounded,
                            color: colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Command Center',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        FilterChip(
                          label: Text(_showCompleted
                              ? 'Completed: ON'
                              : 'Completed: OFF'),
                          selected: _showCompleted,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _showCompleted = !_showCompleted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: Subject.allSubjects.map((subject) {
                          final isSelected = _selectedSubject == subject;
                          final subjects = context.watch<SubjectsProvider>();
                          final displayLabel = subject == Subject.all
                              ? subject
                              : subjects.displayName(subject);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(displayLabel),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedSubject = subject),
                              showCheckmark: false,
                              avatar: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: colorScheme.onPrimaryContainer,
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
              ? SliverToBoxAdapter(
                  child: _EmptyState(
                    colorScheme: colorScheme,
                    onAdd: _showAddAssignmentSheet,
                  ))
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssignmentSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _StudyBuddyTopSheet extends StatelessWidget {
  const _StudyBuddyTopSheet();

  static const int _sheetBackgroundAlpha = 228;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: size.height * 0.76,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(190),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(46),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: ColoredBox(
                    color: colorScheme.surface.withAlpha(_sheetBackgroundAlpha),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: ChatScreen()),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Classes Section ────────────────────────────────────────────────────────

/// Horizontally-scrollable cards showing persistent classes on the Home screen.
class _ClassesSection extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ClassesSection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final classes = context.watch<ClassesProvider>().classes;
    final effectiveNow = context.watch<DevClockProvider>().nowUtc();
    final season2Enabled =
        !effectiveNow.isBefore(kSeason2.startsAtUtc);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Classes',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: season2Enabled
                          ? () => _showAiImportSheet(context)
                          : () => _showSeason2LockedMessage(context),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                      label: const Text('AI Import'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showClassDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (season2Enabled) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.folder_copy_rounded, size: 16),
                    label: const Text('Study guides organizing'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Study guides organizing is now enabled for Season 2.'),
                      ),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Take pics'),
                    onPressed: () => _openStudyBuddy(context),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Gemini organize'),
                    onPressed: () => _openGeminiOrganizer(context),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Upload notes'),
                    onPressed: () => _openStudyBuddy(context),
                  ),
                ],
              ),
            ),
          ],
          // Horizontal list
          SizedBox(
            height: 120,
            child: classes.isEmpty
                ? _EmptyClassesPlaceholder(colorScheme: colorScheme)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: classes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _ClassCard(
                      schoolClass: classes[i],
                      colorScheme: colorScheme,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showClassDialog(BuildContext context, {SchoolClass? existing}) {
    showDialog(
      context: context,
      builder: (_) => _ClassEditDialog(existing: existing),
    );
  }

  void _showAiImportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiClassImportSheet(),
    );
  }

  void _openGeminiOrganizer(BuildContext context) {
    final chat = context.read<ChatProvider>();
    final hasApiKey =
        chat.customApiKey.isNotEmpty || AppSecrets.geminiApiKey.isNotEmpty;
    if (!hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gemini organizer needs an API key. Add one in Settings → AI & Models.',
          ),
        ),
      );
      return;
    }
    _showAiImportSheet(context);
  }

  void _showSeason2LockedMessage(BuildContext context) {
    final starts = kSeason2.startsAtUtc;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Season 2 features unlock on ${starts.month}/${starts.day}/${starts.year} (UTC).',
        ),
      ),
    );
  }

  Future<void> _openStudyBuddy(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'AI Study Buddy',
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(80),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const _StudyBuddyTopSheet(),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.12),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Empty state placeholder for the classes horizontal list.
class _EmptyClassesPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyClassesPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No classes yet — tap Add to create one.',
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A single class card in the horizontal scroll list.
class _ClassCard extends StatelessWidget {
  final SchoolClass schoolClass;
  final ColorScheme colorScheme;

  const _ClassCard({
    required this.schoolClass,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_rounded,
                    size: 18, color: colorScheme.onPrimaryContainer),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showOptions(context),
                  child: Icon(Icons.more_vert_rounded,
                      size: 16, color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              schoolClass.name,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (schoolClass.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                schoolClass.description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withAlpha(180),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClassOptionsSheet(
        schoolClass: schoolClass,
        colorScheme: colorScheme,
      ),
    );
  }
}

/// Bottom-sheet with edit / delete actions for a class.
class _ClassOptionsSheet extends StatelessWidget {
  final SchoolClass schoolClass;
  final ColorScheme colorScheme;

  const _ClassOptionsSheet({
    required this.schoolClass,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: colorScheme.primary),
              title: const Text('Edit class'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => _ClassEditDialog(existing: schoolClass),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: colorScheme.error),
              title: Text('Delete class',
                  style: TextStyle(color: colorScheme.error)),
              onTap: () {
                final provider = context.read<ClassesProvider>();
                Navigator.pop(context);
                provider.deleteClass(schoolClass.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating or editing a class.
class _ClassEditDialog extends StatefulWidget {
  final SchoolClass? existing;

  const _ClassEditDialog({this.existing});

  @override
  State<_ClassEditDialog> createState() => _ClassEditDialogState();
}

class _ClassEditDialogState extends State<_ClassEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late List<String> _subjects;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _subjects = List<String>.from(c?.subjects ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toggleSubject(String canonical) {
    setState(() {
      if (_subjects.contains(canonical)) {
        _subjects.remove(canonical);
      } else {
        _subjects.add(canonical);
      }
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final classesProvider = context.read<ClassesProvider>();
    final existing = widget.existing;

    final updated = SchoolClass(
      id: existing?.id ?? '',
      name: name,
      description: _descCtrl.text.trim(),
      subjects: List<String>.from(_subjects),
    );

    if (existing == null) {
      classesProvider.addClass(updated).then((added) {
        if (!mounted) return;
        if (!added) {
          _showClassLimitDialog(context);
        } else {
          Navigator.pop(context);
        }
      });
    } else {
      classesProvider.updateClass(updated);
      Navigator.pop(context);
    }
  }

  void _showClassLimitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Class Limit Reached'),
          ],
        ),
        content: Text(
          'Classes are unlimited for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;
    final allSubjectNames = Subject.allSubjects
        .where((s) => s != Subject.all)
        .toList();

    return AlertDialog(
      title: Text(isEditing ? 'Edit Class' : 'New Class'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Class name *',
                hintText: 'e.g. AP Biology',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Teacher / description (optional)',
                hintText: 'e.g. Mr. Smith',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Link to Subjects',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allSubjectNames.map((canonical) {
                final isSelected = _subjects.contains(canonical);
                return FilterChip(
                  label: Text(canonical),
                  selected: isSelected,
                  onSelected: (_) => _toggleSubject(canonical),
                  showCheckmark: isSelected,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

/// The motivational header shown at the top of the dashboard.
class _MotivationHeader extends StatelessWidget {
  final String quote;
  final int pendingCount;
  final ColorScheme colorScheme;
  final String greeting;

  const _MotivationHeader({
    required this.quote,
    required this.pendingCount,
    required this.colorScheme,
    required this.greeting,
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
                          DateFormat('EEEE, MMMM d').format(
                            context.watch<DevClockProvider>().nowUtc().toLocal(),
                          ),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outline.withAlpha(60)),
                ),
                child: GradientText(
                  greeting,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF00CFFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
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
  final VoidCallback? onAdd;

  const _EmptyState({required this.colorScheme, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You\'re all clear! 🎉',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No assignments yet. Add one to stay on top of your work!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add assignment'),
          ),
        ],
      ),
    );
  }
}

// ── AI Classroom Import Sheet ─────────────────────────────────────────────────

/// Bottom-sheet that lets the user paste their Google Classroom homepage text.
/// Gemini extracts class names and subjects, which the user can then confirm.
class _AiClassImportSheet extends StatefulWidget {
  const _AiClassImportSheet();

  @override
  State<_AiClassImportSheet> createState() => _AiClassImportSheetState();
}

class _AiClassImportSheetState extends State<_AiClassImportSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<SchoolClass> _parsed = [];
  final Set<int> _selected = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    // Resolve API key: prefer BYOK key, fall back to compile-time key.
    final chatProvider = context.read<ChatProvider>();
    final apiKey = chatProvider.customApiKey.isNotEmpty
        ? chatProvider.customApiKey
        : AppSecrets.geminiApiKey;

    if (apiKey.isEmpty) {
      setState(() => _error =
          'No Gemini API key found.\nGo to Settings → AI & Models to add your key.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _parsed = [];
      _selected.clear();
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      const systemPrompt =
          'You are a class-name extractor for a homework helper app. '
          'The user will paste raw text copied from their Google Classroom homepage. '
          'Extract ONLY actual class/course names (e.g. "AP Biology", "Math 101"). '
          'Ignore assignment names, announcements, teacher names, and dates. '
          'For each class, also suggest the best matching subject from this list: '
          'Math, Science, History, English, Art, Music, P.E., Other. '
          'Return a JSON array like: '
          '[{"name":"AP Biology","subject":"Science"},{"name":"Pre-Calc","subject":"Math"}]. '
          'Return ONLY the JSON array, nothing else.';

      final response = await model.generateContent([
        Content.text('$systemPrompt\n\nClassroom text:\n$text'),
      ]);

      final raw = response.text ?? '';
      // Strip markdown code fences if present.
      final jsonStr =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> items = json.decode(jsonStr) as List<dynamic>;
      final classes = items.map((item) {
        final m = item as Map<String, dynamic>;
        return SchoolClass(
          id: '',
          name: (m['name'] as String? ?? '').trim(),
          subjects: [
            if ((m['subject'] as String?)?.isNotEmpty == true)
              m['subject'] as String,
          ],
        );
      }).where((c) => c.name.isNotEmpty).toList();

      setState(() {
        _parsed = classes;
        _selected.addAll(List.generate(classes.length, (i) => i));
      });
    } catch (e) {
      setState(() =>
          _error = 'Failed to parse classes.\nCheck your API key and try again.\n\nDetails: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addSelected() async {
    final classesProvider = context.read<ClassesProvider>();
    int addedCount = 0;
    bool limitReached = false;
    for (final i in _selected) {
      if (i < _parsed.length) {
        final added = await classesProvider.addClass(_parsed[i]);
        if (added) {
          addedCount++;
        } else {
          limitReached = true;
          break; // Stop at first limit hit — no point trying more
        }
      }
    }
    if (mounted) {
      Navigator.pop(context);
      if (limitReached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addedCount > 0
                  ? '$addedCount class${addedCount == 1 ? '' : 'es'} added. Free limit reached — upgrade for more!'
                  : 'You can keep adding classes.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$addedCount class${addedCount == 1 ? '' : 'es'} added! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keySet = context.watch<ChatProvider>().customApiKey.isNotEmpty ||
        AppSecrets.geminiApiKey.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            // Drag handle
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
              '🤖 AI Classroom Import',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste the text from your Google Classroom homepage. '
              'Gemini will extract your class names and suggest subjects.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (!keySet) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_rounded,
                        color: colorScheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No Gemini API key set. Add one in Settings → AI & Models.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      },
                      child: const Text('Settings'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Paste Google Classroom homepage text here…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _import,
                icon: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colorScheme.onPrimary),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_loading ? 'Analyzing…' : 'Extract Classes'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_parsed.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Found ${_parsed.length} class${_parsed.length == 1 ? '' : 'es'} — select to add:',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ..._parsed.asMap().entries.map((e) {
                final i = e.key;
                final cls = e.value;
                final sel = _selected.contains(i);
                return CheckboxListTile(
                  value: sel,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(i);
                    } else {
                      _selected.remove(i);
                    }
                  }),
                  title: Text(cls.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: cls.subjects.isNotEmpty
                      ? Text(cls.subjects.join(', '))
                      : null,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school_rounded,
                        size: 18, color: colorScheme.onPrimaryContainer),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty ? null : _addSelected,
                  child: Text(
                      'Add ${_selected.length} Class${_selected.length == 1 ? '' : 'es'}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Event Banner Card ─────────────────────────────────────────────────────────

/// A compact Home-screen banner that links to [LadderEventScreen].
/// Shows different copy depending on the event state.
class _EventBannerCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EventBannerCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>();

    String title;
    String subtitle;
    Color accentColor;
    String emoji;

    switch (event.state) {
      case EventState.upcoming:
        title = 'Assignments Ladder – Starting Soon!';
        subtitle = 'Complete assignments Apr 24–30 for big rewards.';
        accentColor = const Color(0xFFFF6B35);
        emoji = '⏳';
      case EventState.active:
        final reached = event.highestReachedTier;
        title = 'Assignments Ladder – Live Now!';
        subtitle = reached > 0
            ? 'Tier $reached reached · ${event.totalCompletedDuringEvent} completed'
            : 'Start completing assignments to earn rewards!';
        accentColor = Colors.green.shade600;
        emoji = '🔥';
      case EventState.ended:
        final unclaimed = event.highestReachedTier - event.claimedTiers.length;
        title = 'Assignments Ladder – Ended';
        subtitle = unclaimed > 0
            ? '$unclaimed unclaimed reward${unclaimed != 1 ? "s" : ""} waiting!'
            : 'Thanks for participating!';
        accentColor = colorScheme.onSurfaceVariant;
        emoji = '🏁';
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LadderEventScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withAlpha(28),
              colorScheme.primaryContainer.withAlpha(50),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withAlpha(90)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
