import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/secrets.dart';
import '../providers/chat_provider.dart';

class StudyToolsScreen extends StatefulWidget {
  final int initialTab;

  const StudyToolsScreen({super.key, this.initialTab = 0});

  @override
  State<StudyToolsScreen> createState() => _StudyToolsScreenState();
}

class _StudyToolsScreenState extends State<StudyToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Study Tools',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notepad'),
            Tab(text: 'Quiz From Pics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotepadTab(),
          _QuizFromPicsTab(),
        ],
      ),
    );
  }
}

class _StudyNote {
  final String id;
  final String text;
  final String? imageBase64;
  final bool pinned;
  final DateTime updatedAt;

  const _StudyNote({
    required this.id,
    required this.text,
    this.imageBase64,
    this.pinned = false,
    required this.updatedAt,
  });

  _StudyNote copyWith({
    String? id,
    String? text,
    String? imageBase64,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return _StudyNote(
      id: id ?? this.id,
      text: text ?? this.text,
      imageBase64: imageBase64 ?? this.imageBase64,
      pinned: pinned ?? this.pinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'imageBase64': imageBase64,
        'pinned': pinned,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory _StudyNote.fromMap(Map<String, dynamic> map) => _StudyNote(
        id: map['id'] as String? ?? '',
        text: map['text'] as String? ?? '',
        imageBase64: map['imageBase64'] as String?,
        pinned: map['pinned'] as bool? ?? false,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class _NotepadTab extends StatefulWidget {
  const _NotepadTab();

  @override
  State<_NotepadTab> createState() => _NotepadTabState();
}

class _NotepadTabState extends State<_NotepadTab> {
  static const _kNotesPrefKey = 'study_notes_v1';

  final List<_StudyNote> _notes = [];
  bool _loading = true;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotesPrefKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _notes
        ..clear()
        ..addAll(decoded
            .whereType<Map>()
            .map((m) => _StudyNote.fromMap(Map<String, dynamic>.from(m))));
    }
    _sortNotes();
    setState(() => _loading = false);
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kNotesPrefKey,
      jsonEncode(_notes.map((n) => n.toMap()).toList()),
    );
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> _addOrEditNote({_StudyNote? existing}) async {
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    String? imageBase64 = existing?.imageBase64;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'New Note' : 'Edit Note',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Write key facts, reminders, formulas, or prompts...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1600,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setModalState(() {
                            imageBase64 = base64Encode(bytes);
                          });
                        },
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Attach Photo'),
                      ),
                      if (imageBase64 != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              imageBase64 = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove Photo'),
                        ),
                    ],
                  ),
                  if (imageBase64 != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(imageBase64!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Text('Could not preview image'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(existing == null ? 'Add' : 'Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (existing == null) {
      _notes.add(_StudyNote(
        id: now.microsecondsSinceEpoch.toString(),
        text: text,
        imageBase64: imageBase64,
        updatedAt: now,
      ));
    } else {
      final i = _notes.indexWhere((n) => n.id == existing.id);
      if (i != -1) {
        _notes[i] = existing.copyWith(
          text: text,
          imageBase64: imageBase64,
          updatedAt: now,
        );
      }
    }

    _sortNotes();
    await _saveNotes();
    if (mounted) setState(() {});
  }

  Future<void> _togglePin(_StudyNote note) async {
    final i = _notes.indexWhere((n) => n.id == note.id);
    if (i == -1) return;
    _notes[i] = note.copyWith(pinned: !note.pinned, updatedAt: DateTime.now());
    _sortNotes();
    await _saveNotes();
    if (mounted) setState(() {});
  }

  Future<void> _deleteNote(_StudyNote note) async {
    _notes.removeWhere((n) => n.id == note.id);
    await _saveNotes();
    if (mounted) setState(() {});
  }

  Future<void> _summarizeNote(_StudyNote note) async {
    final chat = context.read<ChatProvider>();
    final apiKey =
        chat.customApiKey.isNotEmpty ? chat.customApiKey : AppSecrets.geminiApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API key required. Add one in Settings -> AI & Models.'),
        ),
      );
      return;
    }

    setState(() => _summarizing = true);
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final parts = <Part>[
        TextPart(
          'Read this study note and return:\n'
          '1) A short summary (2-3 lines)\n'
          '2) 3 key facts\n'
          '3) 1 memory trick.\n\n'
          'Study note text:\n${note.text}',
        ),
      ];
      if (note.imageBase64 != null) {
        parts.add(DataPart('image/jpeg', base64Decode(note.imageBase64!)));
      }

      final response = await model.generateContent([
        Content.multi(parts),
      ]);

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gemini Note Review'),
          content: SingleChildScrollView(
            child: Text(response.text?.trim().isNotEmpty == true
                ? response.text!.trim()
                : 'No response from Gemini.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not analyze note: $e')),
      );
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No notes yet. Add your first sticky note to save facts and reminders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final note = _notes[i];
                final hasImage = note.imageBase64 != null;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.pinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.push_pin_rounded, size: 18),
                              ),
                            Expanded(
                              child: Text(
                                note.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (hasImage) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(note.imageBase64!),
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _summarizing ? null : () => _summarizeNote(note),
                              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                              label: const Text('Gemini Review'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _addOrEditNote(existing: note),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _togglePin(note),
                              icon: Icon(
                                note.pinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 16,
                              ),
                              label: Text(note.pinned ? 'Unpin' : 'Pin'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _deleteNote(note),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditNote(),
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('Add Note'),
      ),
    );
  }
}

class _QuizFromPicsTab extends StatefulWidget {
  const _QuizFromPicsTab();

  @override
  State<_QuizFromPicsTab> createState() => _QuizFromPicsTabState();
}

class _QuizFromPicsTabState extends State<_QuizFromPicsTab> {
  final _topicCtrl = TextEditingController();
  String? _imageBase64;
  bool _loading = false;
  String? _rawOutput;
  List<Map<String, dynamic>> _questions = [];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
      _questions = [];
      _rawOutput = null;
    });
  }

  Future<void> _generateQuiz() async {
    final chat = context.read<ChatProvider>();
    final apiKey =
        chat.customApiKey.isNotEmpty ? chat.customApiKey : AppSecrets.geminiApiKey;

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API key required. Add one in Settings -> AI & Models.'),
        ),
      );
      return;
    }
    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach a study guide photo first.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _questions = [];
      _rawOutput = null;
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt =
          'Create 5 multiple-choice practice quiz questions from this study guide image. '
          'Topic: ${_topicCtrl.text.trim().isEmpty ? "General" : _topicCtrl.text.trim()}. '
          'Return ONLY valid JSON array. '
          'Each item format: '
          '{"question":"...","options":["A","B","C","D"],"answer":"...","explanation":"..."}.';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', base64Decode(_imageBase64!)),
        ]),
      ]);

      final text = (response.text ?? '').trim();
      final jsonStr = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(jsonStr) as List<dynamic>;
      final questions = parsed
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _questions = questions;
        _rawOutput = text;
      });
    } catch (e) {
      setState(() {
        _rawOutput = 'Could not parse structured quiz. Raw model output:\n$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz generation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TextField(
          controller: _topicCtrl,
          decoration: const InputDecoration(
            labelText: 'Topic (optional)',
            hintText: 'e.g. Cellular Respiration',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Attach Study Guide Photo'),
            ),
            FilledButton.icon(
              onPressed: _loading ? null : _generateQuiz,
              icon: const Icon(Icons.quiz_rounded),
              label: Text(_loading ? 'Generating...' : 'Generate Quiz'),
            ),
          ],
        ),
        if (_imageBase64 != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(_imageBase64!),
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_questions.isEmpty && !_loading)
          Text(
            'Attach a study guide image and generate a Gemini practice quiz.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        if (_questions.isNotEmpty)
          ..._questions.map((q) {
            final options = (q['options'] as List?)?.cast<dynamic>() ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['question']?.toString() ?? 'Question',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...options.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('- ${o.toString()}'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Answer: ${q['answer'] ?? ''}'),
                    if ((q['explanation']?.toString() ?? '').isNotEmpty)
                      Text(
                        'Why: ${q['explanation']}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            );
          }),
        if (_rawOutput != null && _questions.isEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(
            _rawOutput!,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
