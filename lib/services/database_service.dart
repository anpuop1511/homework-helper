import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/assignment.dart';
import '../models/social_models.dart';
import '../providers/theme_provider.dart';

/// Provides Firestore read/write helpers used by the various providers.
///
/// All operations are scoped to the authenticated user's documents:
///   users/{uid}                  – XP, level, streak, vibe, email, username
///   users/{uid}/assignments/{id} – individual assignments
///   users/{uid}/friends/{fid}    – accepted friends (sub-collection)
///   friend_requests/{id}         – global pending friend requests
///   usernames/{handle}           – username → uid mapping for uniqueness checks
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

  /// Writes / merges profile visibility and friend request privacy settings.
  Future<void> savePrivacySettings(
    String uid, {
    required int profileVisibility,
    required int friendRequestsPrivacy,
  }) async {
    await _userDoc(uid).set(
      {
        'profileVisibility': profileVisibility,
        'friendRequestsPrivacy': friendRequestsPrivacy,
      },
      SetOptions(merge: true),
    );
  }

  /// Fetches a public profile for a given @handle.
  /// Returns null if the user doesn't exist.
  Future<Map<String, dynamic>?> getPublicProfile(String handle) async {
    final uid = await lookupUidByUsername(handle.toLowerCase());
    if (uid == null) return null;
    final data = await getUserData(uid);
    if (data == null) return null;
    return {'uid': uid, ...data};
  }

  // ── Username (@handle) ────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _usernameDoc(String handle) =>
      _db.collection('usernames').doc(handle.toLowerCase());

  /// Returns true if [handle] is not already claimed.
  Future<bool> isUsernameAvailable(String handle) async {
    final snap = await _usernameDoc(handle).get();
    return !snap.exists;
  }

  /// Claims [handle] for [uid].  Atomically writes the `usernames` mapping
  /// and stores the username on the user document.
  ///
  /// If the atomic transaction fails (e.g. due to missing collection
  /// permissions on `usernames`), falls back to saving only the username
  /// field on the user's own document so the user is not permanently blocked
  /// behind the Auth Gate.  Owner-only write rules on `users/{uid}` are
  /// assumed to be in place.
  ///
  /// Returns an error message on complete failure, or null on success
  /// (including fallback success).
  Future<String?> claimUsername(String uid, String handle) async {
    final lower = handle.toLowerCase();
    try {
      await _db.runTransaction((tx) async {
        // Read both the target username doc and the user's existing profile
        // so we can clean up any old handle in the same atomic operation.
        final newHandleSnap = await tx.get(_usernameDoc(lower));
        final userSnap = await tx.get(_userDoc(uid));

        if (newHandleSnap.exists) {
          // If the handle is already owned by this user (e.g. a retry after a
          // partial write), just ensure the user document is in sync and
          // treat the operation as successful.
          if (newHandleSnap.data()?['uid'] == uid) {
            tx.set(_userDoc(uid), {'username': lower}, SetOptions(merge: true));
            return;
          }
          throw Exception('taken');
        }

        // Delete the old handle mapping so it doesn't become a ghost entry.
        final oldHandle = userSnap.data()?['username'] as String?;
        if (oldHandle != null && oldHandle != lower) {
          tx.delete(_usernameDoc(oldHandle));
        }

        tx.set(_usernameDoc(lower), {'uid': uid});
        tx.set(_userDoc(uid), {'username': lower}, SetOptions(merge: true));
      });
      return null;
    } catch (e) {
      if (e.toString().contains('taken')) {
        return 'That username is already taken. Try another!';
      }
      // Transaction failed (likely a permission error on the usernames
      // collection).  Fall back to writing just the username field on the
      // user's own document, which only requires owner-only write access.
      try {
        await _userDoc(uid).set(
          {'username': lower},
          SetOptions(merge: true),
        );
        return null;
      } catch (_) {
        return 'Could not save username. Please try again.';
      }
    }
  }

  /// Returns the username stored for [uid], or null if none has been set.
  Future<String?> getUsernameForUid(String uid) async {
    final data = await getUserData(uid);
    return data?['username'] as String?;
  }

  /// Looks up the UID for a given @[handle].  Returns null if not found.
  Future<String?> lookupUidByUsername(String handle) async {
    final snap = await _usernameDoc(handle).get();
    if (!snap.exists) return null;
    return snap.data()?['uid'] as String?;
  }

  // ── Profile photo ─────────────────────────────────────────────────────────

  /// Uploads [bytes] to Firebase Storage and returns the download URL.
  /// Stores the URL in the user document under `photoUrl`.
  Future<String> uploadProfilePhoto(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child('profile_photo.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _userDoc(uid).set({'photoUrl': url}, SetOptions(merge: true));
    return url;
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

  CollectionReference<Map<String, dynamic>> _friendRequestsCol(String uid) =>
      _userDoc(uid).collection('friendRequests');

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
    String fromUsername = '',
    String fromName = '',
  }) async {
    final ref = await _requestsCol.add({
      'from': fromUid,
      'to': toUid,
      'fromEmail': fromEmail,
      'toEmail': toEmail,
      'fromUsername': fromUsername,
      'fromName': fromName,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Also write to the target user's friendRequests subcollection (new model).
    await _friendRequestsCol(toUid).doc(ref.id).set({
      'fromUid': fromUid,
      'fromHandle': fromUsername,
      'createdAt': FieldValue.serverTimestamp(),
      'requestId': ref.id,
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
                fromUsername: d['fromUsername'] as String? ?? '',
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
        'username': request.fromUsername,
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
    // Clean up the subcollection entry.
    try {
      await _friendRequestsCol(request.toUid).doc(request.id).delete();
    } catch (_) {}
  }
  Future<void> declineFriendRequest(String requestId, {String? targetUid}) async {
    await _requestsCol.doc(requestId).delete();
    if (targetUid != null) {
      try {
        await _friendRequestsCol(targetUid).doc(requestId).delete();
      } catch (_) {}
    }
  }

  /// Removes a friend from both users' friends sub-collections.
  Future<void> removeFriend(String currentUid, String friendUid) async {
    final batch = _db.batch();
    batch.delete(_friendsCol(currentUid).doc(friendUid));
    batch.delete(_friendsCol(friendUid).doc(currentUid));
    await batch.commit();
  }

  /// Returns the relationship status between [currentUid] and [targetUid].
  /// Possible values: 'friends', 'request_sent', 'request_received', 'none'.
  Future<String> checkRelationshipStatus(String currentUid, String targetUid) async {
    // Check if already friends.
    final friendDoc = await _friendsCol(currentUid).doc(targetUid).get();
    if (friendDoc.exists) return 'friends';
    // Check for pending request sent by current user.
    final sentSnap = await _requestsCol
        .where('from', isEqualTo: currentUid)
        .where('to', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sentSnap.docs.isNotEmpty) return 'request_sent';
    // Check for incoming request from target user.
    final receivedSnap = await _requestsCol
        .where('from', isEqualTo: targetUid)
        .where('to', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (receivedSnap.docs.isNotEmpty) return 'request_received';
    return 'none';
  }

  /// Returns the ID of a pending request from [fromUid] to [toUid], or null.
  Future<String?> getPendingRequestFromUser({
    required String fromUid,
    required String toUid,
  }) async {
    final snap = await _requestsCol
        .where('from', isEqualTo: fromUid)
        .where('to', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }
}
