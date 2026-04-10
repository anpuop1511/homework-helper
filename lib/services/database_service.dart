import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../models/social_models.dart';
import '../providers/theme_provider.dart';

/// Provides Firestore read/write helpers used by the various providers.
///
/// All operations are scoped to the authenticated user's documents:
///   users/{uid}                  – XP, level, streak, vibe, email
///   users/{uid}/assignments/{id} – individual assignments
///   users/{uid}/friends/{fid}    – accepted friends (sub-collection)
///   friend_requests/{id}         – global pending friend requests
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

  /// Saves the user's email to their document for friend-lookup purposes.
  Future<void> saveUserEmail(String uid, String email) async {
    await _userDoc(uid).set(
      {'email': email.toLowerCase()},
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
      subject: Subject.allSubjects[d['subject'] as int],
      dueDate: DateTime.fromMillisecondsSinceEpoch(d['dueDate'] as int),
      isCompleted: (d['isCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _assignmentToMap(Assignment a) => {
        'title': a.title,
        'subject': Subject.allSubjects.indexOf(a.subject),
        'dueDate': a.dueDate.millisecondsSinceEpoch,
        'isCompleted': a.isCompleted,
      };

  // ── Social / Friends ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _friendsCol(String uid) =>
      _userDoc(uid).collection('friends');

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _db.collection('friend_requests');

  /// Looks up a user document by email.  Returns a map containing 'uid' and
  /// the document fields, or null if no user was found.
  Future<Map<String, dynamic>?> lookupUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return {'uid': doc.id, ...doc.data()};
  }

  /// Creates a pending friend request document.
  /// Returns the new document ID.
  Future<String> sendFriendRequest({
    required String fromUid,
    required String toUid,
    required String fromEmail,
    required String toEmail,
  }) async {
    final ref = await _requestsCol.add({
      'from': fromUid,
      'to': toUid,
      'fromEmail': fromEmail,
      'toEmail': toEmail,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Returns a real-time stream of pending incoming friend requests.
  Stream<List<FriendRequest>> pendingRequestsStream(String uid) {
    return _requestsCol
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return FriendRequest(
                id: doc.id,
                fromUid: d['from'] as String,
                fromEmail: d['fromEmail'] as String? ?? '',
                fromName: d['fromName'] as String? ?? '',
                toUid: d['to'] as String,
                timestamp: (d['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  /// Returns a real-time stream of the user's accepted friends.
  Stream<List<Friend>> friendsStream(String uid) {
    return _friendsCol(uid).snapshots().map((snap) =>
        snap.docs.map((doc) => Friend.fromJson({'id': doc.id, ...doc.data()})).toList());
  }

  /// Accepts a friend request:
  ///   1. Updates the request status to 'accepted'.
  ///   2. Adds each user to the other's friends sub-collection.
  Future<void> acceptFriendRequest(FriendRequest request,
      {required Map<String, dynamic> currentUserData}) async {
    final batch = _db.batch();

    // Update request status.
    batch.update(_requestsCol.doc(request.id), {'status': 'accepted'});

    // Add sender to current user's friends.
    batch.set(
      _friendsCol(request.toUid).doc(request.fromUid),
      {
        'uid': request.fromUid,
        'name': request.fromName.isNotEmpty
            ? request.fromName
            : request.fromEmail.split('@').first,
        'email': request.fromEmail,
        'level': 1,
        'totalXp': 0,
        'streak': 0,
      },
    );

    // Add current user to sender's friends.
    batch.set(
      _friendsCol(request.fromUid).doc(request.toUid),
      currentUserData,
    );

    await batch.commit();
  }

  /// Declines (deletes) a friend request.
  Future<void> declineFriendRequest(String requestId) async {
    await _requestsCol.doc(requestId).delete();
  }

  /// Removes a friend from both users' friends sub-collections.
  Future<void> removeFriend(String currentUid, String friendUid) async {
    final batch = _db.batch();
    batch.delete(_friendsCol(currentUid).doc(friendUid));
    batch.delete(_friendsCol(friendUid).doc(currentUid));
    await batch.commit();
  }
}
