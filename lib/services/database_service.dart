import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../providers/theme_provider.dart';

/// Provides Firestore read/write helpers used by the various providers.
///
/// All operations are scoped to the authenticated user's documents:
///   users/{uid}                  – XP, level, streak, vibe
///   users/{uid}/assignments/{id} – individual assignments
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User data ────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Reads the user document.  Returns null if it does not exist yet.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _userDoc(uid).get();
    return snap.data();
  }

  /// Writes / merges user stats (XP, level, streak, name).
  Future<void> saveUserStats({
    required String uid,
    required int xp,
    required int level,
    required int streak,
    required String name,
    required DateTime lastActiveDate,
  }) async {
    await _userDoc(uid).set(
      {
        'xp': xp,
        'level': level,
        'streak': streak,
        'name': name,
        'lastActiveDate': lastActiveDate.millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
  }

  /// Writes / merges only the vibe field.
  Future<void> saveVibe(String uid, AppVibe vibe) async {
    await _userDoc(uid).set(
      {'vibe': vibe.index},
      SetOptions(merge: true),
    );
  }

  // ── Assignments ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _assignmentsCol(String uid) =>
      _userDoc(uid).collection('assignments');

  /// Returns a real-time stream of the user's assignments, ordered by due date.
  Stream<List<Assignment>> assignmentsStream(String uid) {
    return _assignmentsCol(uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs.map(_docToAssignment).toList());
  }

  /// Writes (or overwrites) a single assignment.
  Future<void> saveAssignment(String uid, Assignment assignment) async {
    await _assignmentsCol(uid).doc(assignment.id).set(_assignmentToMap(assignment));
  }

  /// Deletes a single assignment.
  Future<void> deleteAssignment(String uid, String assignmentId) async {
    await _assignmentsCol(uid).doc(assignmentId).delete();
  }

  /// Bulk-writes a list of assignments (used for local→cloud migration).
  Future<void> bulkSaveAssignments(
      String uid, List<Assignment> assignments) async {
    final batch = _db.batch();
    for (final a in assignments) {
      batch.set(_assignmentsCol(uid).doc(a.id), _assignmentToMap(a));
    }
    await batch.commit();
  }

  // ── Conversion helpers ───────────────────────────────────────────────────

  Assignment _docToAssignment(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Assignment(
      id: doc.id,
      title: d['title'] as String,
      subject: Subject.values[d['subject'] as int],
      dueDate: DateTime.fromMillisecondsSinceEpoch(d['dueDate'] as int),
      isCompleted: (d['isCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _assignmentToMap(Assignment a) => {
        'title': a.title,
        'subject': a.subject.index,
        'dueDate': a.dueDate.millisecondsSinceEpoch,
        'isCompleted': a.isCompleted,
      };
}
