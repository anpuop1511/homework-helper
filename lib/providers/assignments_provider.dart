import 'package:flutter/foundation.dart';
import '../models/assignment.dart';

/// Manages the list of assignments and notifies listeners on changes.
class AssignmentsProvider extends ChangeNotifier {
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

  List<Assignment> get assignments => List.unmodifiable(_assignments);

  int get pendingCount => _assignments.where((a) => !a.isCompleted).length;

  /// Adds a new assignment and notifies listeners.
  void add(Assignment assignment) {
    _assignments.add(assignment);
    notifyListeners();
  }

  /// Toggles the completion state of an assignment by [id].
  void toggleComplete(String id) {
    final idx = _assignments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _assignments[idx].isCompleted = !_assignments[idx].isCompleted;
      notifyListeners();
    }
  }

  /// Deletes the assignment with the given [id].
  void delete(String id) {
    _assignments.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
