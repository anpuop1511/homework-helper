import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/assignment.dart';
import '../models/class_model.dart';
import '../models/entitlement_model.dart';
import '../models/social_models.dart';
import '../providers/theme_provider.dart';

/// Provides Firestore read/write helpers used by the various providers.
///
/// All operations are scoped to the authenticated user's documents:
///   users/{uid}                  – XP, level, streak, vibe, email, username
///   users/{uid}/assignments/{id} – individual assignments
///   users/{uid}/entitlements/subscription – subscription entitlement
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

  /// Writes / merges Battle Pass data to the user document.
  Future<void> saveBattlePassData({
    required String uid,
    required int coins,
    required int seasonTier,
    required int seasonXp,
    required String passType,
    required String activeSeasonId,
    required List<String> unlockedCosmetics,
    required String activeNameplate,
    required List<int> claimedTiers,
    Map<String, int> seasonTierHistory = const {},
    Map<String, String> seasonPassHistory = const {},
    String equippedBadge = '',
    String equippedNameColor = '',
  }) async {
    await _userDoc(uid).set(
      {
        'bp_coins': coins,
        'bp_seasonTier': seasonTier,
        'bp_seasonXp': seasonXp,
        'bp_passType': passType,
        'bp_activeSeasonId': activeSeasonId,
        'bp_seasonTierHistory': seasonTierHistory,
        'bp_seasonPassHistory': seasonPassHistory,
        'bp_unlockedCosmetics': unlockedCosmetics,
        'bp_activeNameplate': activeNameplate,
        'bp_claimedTiers': claimedTiers,
        'bp_equippedBadge': equippedBadge,
        'bp_equippedNameColor': equippedNameColor,
      },
      SetOptions(merge: true),
    );
  }

  // ── Subscription entitlements ────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _entitlementDoc(String uid) =>
      _userDoc(uid).collection('entitlements').doc('subscription');

  /// Returns a real-time [Stream] of the user's [SubscriptionEntitlement].
  ///
  /// Emits `null` when the document does not exist (caller should treat as
  /// [SubscriptionEntitlement.free]).
  Stream<SubscriptionEntitlement?> entitlementsStream(String uid) {
    return _entitlementDoc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return SubscriptionEntitlement.fromFirestore(data);
    });
  }

  /// Writes (merge) an entitlement document for [uid].
  ///
  /// The [updatedAt] field is always overwritten with a server timestamp so
  /// the record has an authoritative modification time.
  Future<void> saveEntitlements(
      String uid, SubscriptionEntitlement entitlement) async {
    await _entitlementDoc(uid).set(
      entitlement.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Sets the one-time promo flag [field] to `true` on the entitlement
  /// document (e.g. `earned_plus_30d_trial_from_ladder`).
  ///
  /// This is a targeted write so it does not clobber other entitlement fields.
  Future<void> setEntitlementFlag(String uid, String field) async {
    await _entitlementDoc(uid).set(
      {field: true, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ── Limited-time event data ───────────────────────────────────────────────

  /// Writes / merges event progress into a sub-document at
  /// `users/{uid}/events/{eventId}`.
  Future<void> saveEventData({
    required String uid,
    required String eventId,
    required int total,
    required List<int> claimedTiers,
    required List<String> countedIds,
  }) async {
    await _userDoc(uid)
        .collection('events')
        .doc(eventId)
        .set(
      {
        'total': total,
        'claimed': claimedTiers,
        'countedIds': countedIds,
      },
      SetOptions(merge: true),
    );
  }

  /// Reads event progress from `users/{uid}/events/{eventId}`.
  /// Returns null if the document does not exist.
  Future<Map<String, dynamic>?> getEventData(
      String uid, String eventId) async {
    final snap = await _userDoc(uid).collection('events').doc(eventId).get();
    return snap.data();
  }

  /// Writes / merges only the vibe field.
  Future<void> saveVibe(String uid, AppVibe vibe) async {
    await _userDoc(uid).set(
      {'vibe': vibe.index},
      SetOptions(merge: true),
    );
  }

  /// Updates the user's display name and bio in their Firestore document.
  Future<void> updateProfile(
    String uid,
    String displayName,
    String bio,
  ) async {
    await _userDoc(uid).set(
      {
        'name': displayName,
        'bio': bio,
      },
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
  ///
  /// Values are stored as their enum [name] strings (not integer indices) so
  /// that reordering the enum in future code cannot corrupt existing records
  /// (M-5).
  Future<void> savePrivacySettings(
    String uid, {
    required String profileVisibility,
    required String friendRequestsPrivacy,
  }) async {
    await _userDoc(uid).set(
      {
        'profileVisibility': profileVisibility,
        'friendRequestsPrivacy': friendRequestsPrivacy,
      },
      SetOptions(merge: true),
    );
  }

  /// Fetches a public profile for a given @handle or email address.
  ///
  /// When [handle] looks like an email address (contains `@`) the lookup is
  /// done by email; otherwise the username mapping in `usernames/{handle}` is
  /// used.  Returns null if the user doesn't exist.
  Future<Map<String, dynamic>?> getPublicProfile(String handle) async {
    // Email-based lookup.
    if (handle.contains('@')) {
      final userData = await lookupUserByEmail(handle.toLowerCase());
      return userData; // already contains 'uid' + document fields
    }
    // Username-based lookup.
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

  /// Streams the username for [uid], filtering out stale cache-only null
  /// snapshots that can occur on web page-refresh before Firestore has synced.
  ///
  /// Only emits when:
  /// - the snapshot already has a non-null handle (safe to use immediately
  ///   whether from cache or server), OR
  /// - the snapshot comes from the Firestore server (authoritative result,
  ///   even if the username is null — meaning the user genuinely has none).
  ///
  /// This prevents the "Choose a Handle" screen from flashing when a signed-in
  /// user's handle exists on the server but the local cache is empty or stale.
  Stream<String?> usernameStream(String uid) {
    return _userDoc(uid)
        .snapshots(includeMetadataChanges: true)
        .where((snap) {
          final handle = snap.data()?['username'] as String?;
          // Accept immediately when the cache already has the handle.
          // Otherwise wait for the server-confirmed snapshot.
          return handle != null || !snap.metadata.isFromCache;
        })
        .map((snap) => snap.data()?['username'] as String?);
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
    final d = doc.data() ?? {};
    // L-1: provide safe fallbacks for missing/null fields so the stream
    // never crashes on a malformed or partially-written Firestore document.
    final title = (d['title'] as String?) ?? 'Untitled';
    final dueMs = d['dueDate'];
    final dueDate = dueMs is int
        ? DateTime.fromMillisecondsSinceEpoch(dueMs)
        : DateTime.now().add(const Duration(days: 7));
    final isCompleted = (d['isCompleted'] as bool?) ?? false;
    final rewardsClaimed = (d['rewardsClaimed'] as bool?) ?? false;

    // L-2: subject is stored as its string name since v2.7+.
    // Fall back to index-based lookup for documents written before the migration.
    final subjectRaw = d['subject'];
    String subject;
    if (subjectRaw is String && Subject.allSubjects.contains(subjectRaw)) {
      subject = subjectRaw;
    } else if (subjectRaw is int &&
        subjectRaw >= 0 &&
        subjectRaw < Subject.allSubjects.length) {
      subject = Subject.allSubjects[subjectRaw];
    } else {
      subject = Subject.other;
    }

    return Assignment(
      id: doc.id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      isCompleted: isCompleted,
      rewardsClaimed: rewardsClaimed,
    );
  }

  Map<String, dynamic> _assignmentToMap(Assignment a) => {
        'title': a.title,
        // L-2: store subject as its string name, not an integer index.
        'subject': a.subject,
        'dueDate': a.dueDate.millisecondsSinceEpoch,
        'isCompleted': a.isCompleted,
        'rewardsClaimed': a.rewardsClaimed,
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
  ///
  /// The primary write to `friend_requests` is authoritative; the secondary
  /// write to the target user's `friendRequests` subcollection is best-effort
  /// and will not surface an error if it fails (e.g. due to permission rules).
  Future<String> sendFriendRequest({
    required String fromUid,
    required String toUid,
    required String fromEmail,
    required String toEmail,
    String fromUsername = '',
    String fromName = '',
    String toUsername = '',
  }) async {
    final ref = await _requestsCol.add({
      'from': fromUid,
      'to': toUid,
      'fromEmail': fromEmail,
      'toEmail': toEmail,
      'fromUsername': fromUsername,
      'fromName': fromName,
      'toUsername': toUsername,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Best-effort secondary write to the target user's friendRequests subcollection.
    // If this fails (e.g. due to permission rules) the primary write already
    // succeeded and the request is live in friend_requests.
    try {
      await _friendRequestsCol(toUid).doc(ref.id).set({
        'fromUid': fromUid,
        'fromUsername': fromUsername,
        'createdAt': FieldValue.serverTimestamp(),
        'requestId': ref.id,
      });
    } catch (_) {
      // Secondary write failure is non-fatal; the global request is already written.
    }
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

  /// Returns a real-time stream of pending outgoing (sent) friend requests.
  Stream<List<SentRequest>> sentRequestsStream(String uid) {
    return _requestsCol
        .where('from', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return SentRequest(
                id: doc.id,
                toUid: d['to'] as String,
                toEmail: d['toEmail'] as String? ?? '',
                toUsername: d['toUsername'] as String? ?? '',
                timestamp: (d['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  /// Cancels an outgoing friend request by deleting the global document.
  Future<void> cancelSentRequest(String requestId) async {
    await _requestsCol.doc(requestId).delete();
  }

  /// Returns a real-time stream of the user's accepted friends.
  Stream<List<Friend>> friendsStream(String uid) {
    return _friendsCol(uid).snapshots().map((snap) =>
        snap.docs.map((doc) => Friend.fromJson({'id': doc.id, ...doc.data()})).toList());
  }

  /// Accepts a friend request atomically:
  ///   1. Updates the global request status to 'accepted'.
  ///   2. Adds the sender to the accepter's friends sub-collection.
  ///   3. Adds the accepter to the sender's friends sub-collection (two-way).
  ///   4. Deletes the incoming subcollection entry (cleanup).
  ///
  /// Both friend writes are included in the same batch so the relationship
  /// is always symmetric.  Firestore security rules must permit each user to
  /// write to the other's `users/{uid}/friends/` sub-collection when
  /// accepting a request (e.g. allow write if the writer owns the *other*
  /// document in the request).
  Future<void> acceptFriendRequest(FriendRequest request,
      {required Map<String, dynamic> currentUserData}) async {
    // Fetch the sender's actual stats so we write real level/XP/streak instead
    // of hardcoded defaults.  If the fetch fails we fall back to zeros.
    Map<String, dynamic>? senderData;
    try {
      senderData = await getUserData(request.fromUid);
    } catch (_) {
      // Firestore unavailable — fallback values will be used below.
    }
    // Compute totalXp from the stored per-level xp and level fields using the
    // same formula as UserProvider (baseXp=100, totalXp = 100*(L-1)*L/2 + xp).
    const baseXp = 100;
    final senderLevel = senderData?['level'] as int? ?? 1;
    final senderXp = senderData?['xp'] as int? ?? 0;
    final senderTotalXp = baseXp * (senderLevel - 1) * senderLevel ~/ 2 + senderXp;

    final batch = _db.batch();

    // 1. Mark global request as accepted.
    batch.update(_requestsCol.doc(request.id), {'status': 'accepted'});

    // 2. Add sender to the accepter's friends with their actual stats.
    batch.set(
      _friendsCol(request.toUid).doc(request.fromUid),
      {
        'uid': request.fromUid,
        'name': request.fromName.isNotEmpty
            ? request.fromName
            : request.fromEmail.split('@').first,
        'email': request.fromEmail,
        'username': request.fromUsername,
        'level': senderLevel,
        'totalXp': senderTotalXp,
        'streak': senderData?['streak'] as int? ?? 0,
        if ((senderData?['bp_passType'] as String?) != null &&
            senderData!['bp_passType'] != 'free')
          'passType': senderData['bp_passType'],
        if ((senderData?['bp_equippedBadge'] as String?) != null &&
            (senderData!['bp_equippedBadge'] as String).isNotEmpty)
          'equippedBadge': senderData['bp_equippedBadge'],
      },
    );

    // 3. Add the accepter to the sender's friends list (two-way sync in same batch).
    batch.set(
      _friendsCol(request.fromUid).doc(request.toUid),
      {
        'uid': currentUserData['uid'],
        'name': currentUserData['name'],
        'email': currentUserData['email'],
        'username': currentUserData['username'],
        'level': currentUserData['level'],
        'totalXp': currentUserData['totalXp'],
        'streak': currentUserData['streak'],
        if ((currentUserData['passType'] as String?) != null &&
            currentUserData['passType'] != 'free')
          'passType': currentUserData['passType'],
        if ((currentUserData['equippedBadge'] as String?) != null &&
            (currentUserData['equippedBadge'] as String).isNotEmpty)
          'equippedBadge': currentUserData['equippedBadge'],
      },
    );

    // 4. Clean up the accepter's incoming subcollection entry.
    batch.delete(_friendRequestsCol(request.toUid).doc(request.id));

    // Commit all four operations atomically so both users always see the
    // friendship immediately after acceptance.
    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId, {String? targetUid}) async {
    await _requestsCol.doc(requestId).delete();
    if (targetUid != null) {
      try {
        await _friendRequestsCol(targetUid).doc(requestId).delete();
      } catch (_) {}
    }
  }

  /// Removes a friend atomically from both users' friends sub-collections and
  /// cleans up all related friend-request documents between the two users.
  ///
  /// Steps (single batch commit):
  ///   1. Delete `users/{currentUid}/friends/{friendUid}`.
  ///   2. Delete `users/{friendUid}/friends/{currentUid}`.
  ///   3. Delete any global `friend_requests` docs in either direction.
  ///   4. Delete the corresponding per-user `friendRequests` subcollection
  ///      entries (the incoming-notification copies).
  ///
  /// Safe to call multiple times – extra deletes on non-existent docs are
  /// no-ops in Firestore batches (idempotent).
  Future<void> removeFriend(String currentUid, String friendUid) async {
    // Pre-fetch request IDs in both directions so we can include them in the
    // batch (Firestore batches are write-only and cannot execute queries).
    final results = await Future.wait([
      _requestsCol
          .where('from', isEqualTo: currentUid)
          .where('to', isEqualTo: friendUid)
          .get(),
      _requestsCol
          .where('from', isEqualTo: friendUid)
          .where('to', isEqualTo: currentUid)
          .get(),
    ]);
    final currentToFriendDocs = results[0].docs; // currentUid → friendUid requests
    final friendToCurrentDocs = results[1].docs; // friendUid → currentUid requests

    final batch = _db.batch();

    // 1 & 2 – Remove friendship from both sides.
    batch.delete(_friendsCol(currentUid).doc(friendUid));
    batch.delete(_friendsCol(friendUid).doc(currentUid));

    // 3 – Delete all global friend-request docs between the two users.
    for (final doc in currentToFriendDocs) {
      batch.delete(doc.reference);
    }
    for (final doc in friendToCurrentDocs) {
      batch.delete(doc.reference);
    }

    // 4 – Delete per-user friendRequests subcollection entries (notification
    //     copies).  currentToFriendDocs were delivered to friendUid;
    //     friendToCurrentDocs were delivered to currentUid.
    for (final doc in currentToFriendDocs) {
      batch.delete(_friendRequestsCol(friendUid).doc(doc.id));
    }
    for (final doc in friendToCurrentDocs) {
      batch.delete(_friendRequestsCol(currentUid).doc(doc.id));
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('[DatabaseService] removeFriend batch commit failed: $e');
      rethrow;
    }
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

  // ── Classes ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _classesCol(String uid) =>
      _userDoc(uid).collection('classes');

  /// Returns a real-time stream of the user's classes, ordered by name.
  Stream<List<SchoolClass>> watchClasses(String uid) {
    return _classesCol(uid)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(SchoolClass.fromFirestore).toList());
  }

  /// Adds a new class and returns its generated ID.
  Future<String> addClass(String uid, SchoolClass schoolClass) async {
    final ref = await _classesCol(uid).add(schoolClass.toFirestore());
    return ref.id;
  }

  /// Updates an existing class document (full overwrite of writable fields).
  Future<void> updateClass(String uid, SchoolClass schoolClass) async {
    await _classesCol(uid)
        .doc(schoolClass.id)
        .set(schoolClass.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes a class and all its data.
  Future<void> deleteClass(String uid, String classId) async {
    await _classesCol(uid).doc(classId).delete();
  }
}
