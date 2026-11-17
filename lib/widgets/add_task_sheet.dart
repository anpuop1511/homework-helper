import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/assignment.dart';
import '../models/assignment_template.dart';
import '../providers/assignments_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/entitlements_provider.dart';
import '../screens/upsell_screen.dart';
import '../utils/due_date.dart' as due;

/// A modal bottom sheet for adding a new assignment.
/// Uses [ChoiceChip]s for subject selection and [showDatePicker] for the due date.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _selectedSubject = Subject.math;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _scanning = false;

  /// Whether this assignment should repeat.  Gated behind Plus/Pass.
  bool _isRepeatable = false;

  /// Weekday the repeating template spawns on (DateTime.monday..sunday).
  /// Defaults to the picked due date's weekday and follows it when the
  /// date changes, until the user picks a different weekday by hand.
  late int _selectedWeekday;

  /// Rough estimate of how long the assignment takes, in minutes.
  /// Null = the user gave no estimate.
  int? _estimatedMinutes;

  static const List<int?> _estimateOptions = [null, 15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _selectedWeekday = _dueDate.weekday;
  }

  static const List<String> _subjectOptions = [
    Subject.math,
    Subject.science,
    Subject.history,
    Subject.english,
    Subject.art,
    Subject.music,
    Subject.pe,
    Subject.other,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Uses the device camera (or gallery) to capture a worksheet photo,
  /// then calls Gemini Vision to extract the task title and pre-fills the field.
  Future<void> _scanWorksheet() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() => _scanning = true);
    final extracted =
        await context.read<ChatProvider>().extractTaskFromImage(bytes);
    if (!mounted) return;
    setState(() => _scanning = false);

    if (extracted != null && extracted.isNotEmpty) {
      _titleController.text = extracted;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not extract a task title. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _selectedWeekday = picked.weekday;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<AssignmentsProvider>();
      final now = DateTime.now();
      final title = _titleController.text.trim();

      // When repeating, the template owns the schedule.  The one-off
      // assignment below is created FIRST (tagged with the template id) so
      // the template's spawn guard sees it and does not spawn a duplicate
      // for today.  If the picked due date is today and matches the
      // template weekday, it also counts as this week's spawn.
      String? templateId;
      if (_isRepeatable) {
        templateId = now.millisecondsSinceEpoch.toString();
      }
      final assignment = Assignment(
        id: (now.millisecondsSinceEpoch + 1).toString(),
        title: title,
        subject: _selectedSubject,
        dueDate: _dueDate,
        estimatedMinutes: _estimatedMinutes,
        templateId: templateId,
      );
      provider.add(assignment);
      if (_isRepeatable) {
        final isThisWeeksOccurrence =
            due.dateOnly(_dueDate) == due.dateOnly(now) &&
                _dueDate.weekday == _selectedWeekday;
        provider.addTemplate(AssignmentTemplate(
          id: templateId!,
          title: title,
          subject: _selectedSubject,
          weekday: _selectedWeekday,
          estimatedMinutes: _estimatedMinutes,
          lastSpawnedDate:
              isThisWeeksOccurrence ? due.dateOnly(_dueDate) : null,
        ));
      }
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
            // Sheet drag handle
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Assignment',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // AI Lens: scan a worksheet to auto-fill the title
                _scanning
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        tooltip: 'Scan worksheet with AI',
                        onPressed: _scanWorksheet,
                      ),
              ],
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
            // Subject selection with ChoiceChips
            Text(
              'Subject',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjectOptions.map((subject) {
                final isSelected = _selectedSubject == subject;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedSubject = subject),
                  showCheckmark: false,
                );
              }).toList(),
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
            // Time estimate — feeds "Tonight's workload" on Home.
            Text(
              'How long will it take?',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _estimateOptions.map((minutes) {
                final isSelected = _estimatedMinutes == minutes;
                return ChoiceChip(
                  label: Text(minutes == null
                      ? 'No estimate'
                      : due.formatEstimatedMinutes(minutes)),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _estimatedMinutes = minutes),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Repeatable task toggle (Plus/Pass only)
            _RepeatableToggle(
              isRepeatable: _isRepeatable,
              onChanged: (value) => setState(() => _isRepeatable = value),
            ),
            // Weekday picker for the repeating template.
            if (_isRepeatable) ...[
              const SizedBox(height: 16),
              Text(
                'Repeat every',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                  DateTime.sunday,
                ].map((weekday) {
                  final isSelected = _selectedWeekday == weekday;
                  return ChoiceChip(
                    label: Text(_weekdayShortLabel(weekday)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedWeekday = weekday),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'A new copy of this task will be created every ${_weekdayLongLabel(_selectedWeekday)}.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

String _weekdayShortLabel(int weekday) {
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

String _weekdayLongLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return '';
  }
}

/// Toggle for the repeatable-task feature.
class _RepeatableToggle extends StatelessWidget {
  final bool isRepeatable;
  final ValueChanged<bool> onChanged;

  const _RepeatableToggle({
    required this.isRepeatable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(Icons.repeat_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Repeatable Task',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(28),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Free',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Creates a weekly template — a new copy of this task spawns every week on the day you pick.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isRepeatable,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
