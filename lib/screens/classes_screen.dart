import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/assignment.dart';
import '../models/class_model.dart';
import '../providers/classes_provider.dart';
import '../providers/entitlements_provider.dart';
import '../providers/subjects_provider.dart';
import 'upsell_screen.dart';

/// Full-page screen that lists all user-created [SchoolClass] objects.
///
/// Accessible as an optional bottom-navigation tab (opt-in via Settings →
/// Navigation).  Provides add, edit, and delete operations on classes.
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final classes = context.watch<ClassesProvider>().classes;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Classes',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add class',
            onPressed: () => _showEditDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: classes.isEmpty
          ? _EmptyState(colorScheme: colorScheme)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: classes.length,
              itemBuilder: (_, i) => _ClassListTile(
                schoolClass: classes[i],
                colorScheme: colorScheme,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  void _showEditDialog(BuildContext context, {SchoolClass? existing}) {
    showDialog<void>(
      context: context,
      builder: (_) => _ClassEditDialog(existing: existing),
    );
  }
}

// ── Class list tile ──────────────────────────────────────────────────────────

class _ClassListTile extends StatelessWidget {
  final SchoolClass schoolClass;
  final ColorScheme colorScheme;

  const _ClassListTile({
    required this.schoolClass,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsProvider>();
    final displaySubjects = schoolClass.subjects
        .map((s) => subjects.displayName(s))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.school_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        title: Text(
          schoolClass.name,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schoolClass.description.isNotEmpty)
              Text(
                schoolClass.description,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (displaySubjects.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: displaySubjects
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant),
          onPressed: () => _showOptions(context),
        ),
        onTap: () => _showOptions(context),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
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
                  showDialog<void>(
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
                  context.read<ClassesProvider>().deleteClass(schoolClass.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 52,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No classes yet',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first class.\nYou can link classes to subjects for better organization.',
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

// ── Edit / Create dialog ─────────────────────────────────────────────────────

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
          // Free-tier limit reached — show upgrade CTA.
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
          'Free accounts can create up to $kFreeClassLimit classes. '
          'Upgrade to Helper+ or Helper Pass for unlimited classes and '
          'many more features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close the edit dialog too
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpsellScreen()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subjectsProvider = context.watch<SubjectsProvider>();
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
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              'Link to Subjects',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allSubjectNames.map((canonical) {
                final displayName = subjectsProvider.displayName(canonical);
                final isSelected = _subjects.contains(canonical);
                return FilterChip(
                  label: Text(displayName),
                  selected: isSelected,
                  onSelected: (_) => _toggleSubject(canonical),
                  showCheckmark: isSelected,
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
