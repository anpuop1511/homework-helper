import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_project.dart';

/// Manages Group Projects: create, join, leave, and real-time Firestore sync.
///
/// Projects are stored globally under `projects/{projectId}`.
/// A user's project membership is tracked via `memberUids` array.
class ProjectsProvider extends ChangeNotifier {
  String? _uid;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<GroupProject> _projects = [];
  List<GroupProject> get projects => List.unmodifiable(_projects);

  StreamSubscription<QuerySnapshot>? _sub;

  void setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _projects = [];
    if (uid != null) {
      _subscribe(uid);
    }
    notifyListeners();
  }

  void _subscribe(String uid) {
    _sub = _db
        .collection('projects')
        .where('memberUids', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _projects = snap.docs
          .map((d) =>
              GroupProject.fromJson(d.id, d.data()))
          .toList();
      notifyListeners();
    }, onError: (_) {});
  }

  /// Creates a new project with the current user as owner and first member.
  ///
  /// Returns `(id: projectId, error: null)` on success, or
  /// `(id: null, error: humanReadableMessage)` on failure.
  Future<({String? id, String? error})> createProject({
    required String name,
    String description = '',
  }) async {
    if (_uid == null) {
      return (id: null, error: 'You must be signed in to create a project.');
    }
    try {
      final ref = await _db.collection('projects').add(
            GroupProject(
              id: '',
              name: name.trim(),
              description: description.trim(),
              createdAt: DateTime.now(),
              ownerUid: _uid!,
              memberUids: [_uid!],
            ).toJson(),
          );
      return (id: ref.id, error: null);
    } on FirebaseException catch (e) {
      final msg = switch (e.code) {
        'permission-denied' =>
          'Permission denied. Check your Firestore security rules.',
        'unavailable' || 'network-request-failed' =>
          'Network error. Check your connection and try again.',
        _ => 'Could not create project (${e.code}). Please try again.',
      };
      return (id: null, error: msg);
    } catch (_) {
      return (id: null, error: 'Could not create project. Please try again.');
    }
  }

  /// Joins an existing project by ID. Returns an error string on failure.
  Future<String?> joinProject(String projectId) async {
    if (_uid == null) return 'Not signed in.';
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      if (!doc.exists) return 'Project not found.';
      await _db.collection('projects').doc(projectId).update({
        'memberUids': FieldValue.arrayUnion([_uid!]),
      });
      return null;
    } catch (e) {
      return 'Could not join project: $e';
    }
  }

  /// Fetches a single project by ID (used by JoinProjectScreen before joining).
  Future<GroupProject?> getProject(String projectId) async {
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      if (!doc.exists) return null;
      return GroupProject.fromJson(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Leaves a project (removes the current user from memberUids).
  Future<void> leaveProject(String projectId) async {
    if (_uid == null) return;
    await _db.collection('projects').doc(projectId).update({
      'memberUids': FieldValue.arrayRemove([_uid!]),
    });
  }

  // ── Bulletin posts ────────────────────────────────────────────────────────

  Stream<List<BulletinPost>> bulletinStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('bulletins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BulletinPost.fromJson(d.id, d.data()))
            .toList());
  }

  Future<void> addPost({
    required String projectId,
    required String authorHandle,
    required String text,
  }) async {
    if (_uid == null) return;
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('bulletins')
        .add(BulletinPost(
          id: '',
          authorUid: _uid!,
          authorHandle: authorHandle,
          text: text.trim(),
          createdAt: DateTime.now(),
        ).toJson());
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Stream<List<ProjectTask>> taskStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProjectTask.fromJson(d.id, d.data())).toList());
  }

  Future<void> addTask({
    required String projectId,
    required String title,
    String assigneeUid = '',
  }) async {
    if (_uid == null) return;
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add(ProjectTask(
          id: '',
          title: title.trim(),
          assigneeUid: assigneeUid,
          status: TaskStatus.todo,
          createdAt: DateTime.now(),
        ).toJson());
  }

  Future<void> updateTaskStatus({
    required String projectId,
    required String taskId,
    required TaskStatus status,
  }) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'status': status.name});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
