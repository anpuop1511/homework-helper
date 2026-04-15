import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/assignment.dart';
import '../providers/assignments_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/entitlements_provider.dart';
import '../screens/upsell_screen.dart';

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
      context.read<AssignmentsProvider>().add(assignment);
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
            // Repeatable task toggle (Plus/Pass only)
            _RepeatableToggle(
              isRepeatable: _isRepeatable,
              onChanged: (value) => setState(() => _isRepeatable = value),
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

/// Toggle for the repeatable-task feature.  Locked behind Helper+ / Helper Pass.
///
/// When the user is on the free tier, tapping the row opens the upsell screen
/// instead of toggling the switch.
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
    final entitlements = context.watch<EntitlementsProvider>();
    final hasAccess = entitlements.canUseRepeatableTasks;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: hasAccess
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpsellScreen()),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAccess
                ? colorScheme.outlineVariant.withAlpha(80)
                : colorScheme.outlineVariant.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              color: hasAccess
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withAlpha(120),
            ),
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
                          color: hasAccess
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                      if (!hasAccess) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Helper+',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    hasAccess
                        ? 'Mark this task as repeatable.'
                        : 'Upgrade to Helper+ to use repeatable tasks.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAccess)
              Switch(
                value: isRepeatable,
                onChanged: onChanged,
              )
            else
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
