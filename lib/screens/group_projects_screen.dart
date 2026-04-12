import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/group_project.dart';
import '../providers/auth_provider.dart';
import '../providers/projects_provider.dart';

const _kBlue = Color(0xFF007FFF);

enum _ProjectAction { leave }

// ── Group Projects List Screen ────────────────────────────────────────────────

/// Shows a bottom sheet for joining a project by ID or invite link.
void _showGroupJoinSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final codeController = TextEditingController();
  bool joining = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  'Join a Group Project',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste an invite link or enter a project ID.',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: codeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'homeworkhelper://project/... or project ID',
                    prefixIcon: const Icon(Icons.link_rounded),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: joining
                        ? null
                        : () async {
                            final raw = codeController.text.trim();
                            if (raw.isEmpty) return;
                            String projectId = raw;
                            final uri = Uri.tryParse(raw);
                            if (uri != null &&
                                uri.pathSegments.isNotEmpty) {
                              projectId = uri.pathSegments.last;
                            }
                            setSheetState(() => joining = true);
                            final error = await ctx
                                .read<ProjectsProvider>()
                                .joinProject(projectId);
                            if (!ctx.mounted) return;
                            setSheetState(() => joining = false);
                            Navigator.of(ctx).pop();
                            if (error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Joined project! 🎉'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(
                                      projectId: projectId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor:
                                      colorScheme.errorContainer,
                                ),
                              );
                            }
                          },
                    icon: joining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.login_rounded),
                    label: Text(
                      joining ? 'Joining…' : 'Join Project',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Entry screen for Current Projects – lists the user's projects and lets them
/// create a new one or join an existing one.
class GroupProjectsScreen extends StatelessWidget {
  const GroupProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final projects = context.watch<ProjectsProvider>().projects;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Current Projects',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login_rounded),
            tooltip: 'Join project',
            onPressed: () => _showGroupJoinSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create project',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
            ),
          ),
        ],
      ),
      body: projects.isEmpty
          ? _EmptyProjectsPlaceholder(colorScheme: colorScheme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final project = projects[i];
                return FadeInUp(
                  delay: Duration(milliseconds: i * 60),
                  duration: const Duration(milliseconds: 350),
                  child: _ProjectTile(
                    project: project,
                    colorScheme: colorScheme,
                    onTap: () => Navigator.of(ctx).push(MaterialPageRoute(
                      builder: (_) =>
                          ProjectDetailScreen(projectId: project.id),
                    )),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _EmptyProjectsPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyProjectsPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_work_rounded, size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No group projects yet',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one or join via an invite link.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final GroupProject project;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.project,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kBlue.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.group_work_rounded, color: _kBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${project.memberUids.length} member${project.memberUids.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Project Screen ──────────────────────────────────────────────────────

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final provider = context.read<ProjectsProvider>();
    final result = await provider.createProject(
      name: name,
      description: _descController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.id != null) {
      // Replace create screen with detail screen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: result.id!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to create project. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'New Project',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              'Project Name',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. Biology Study Group',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Description (optional)',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What is this project about?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _loading ? null : _create,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  'Create Project',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project Detail Screen ─────────────────────────────────────────────────────

/// Shows a project's bulletin board and tasks in a tab layout.
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  GroupProject? _directProject;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Defer the Firestore fallback load so we can read the provider first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  /// If the project is already in the provider list we show it immediately.
  /// Otherwise fall back to a direct Firestore fetch with a timeout so the
  /// screen never gets stuck on the spinner forever.
  Future<void> _ensureLoaded() async {
    if (!mounted) return;
    final inList = context
        .read<ProjectsProvider>()
        .projects
        .cast<GroupProject?>()
        .firstWhere((p) => p?.id == widget.projectId, orElse: () => null);
    if (inList != null) return; // already available – build() will show it.

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (!doc.exists) {
        setState(() {
          _error = 'Project not found or has been deleted.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _directProject = GroupProject.fromJson(doc.id, doc.data()!);
        _loading = false;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = "Couldn't load project. Check your connection and try again.";
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final msg = e.code == 'permission-denied'
            ? "You don't have permission to view this project."
            : "Couldn't load project (${e.code}). Please try again.";
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = "Couldn't load project. Please try again.";
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles the Leave / Delete project action with role-aware dialogs.
  Future<void> _handleLeaveOrDelete(
      BuildContext context, GroupProject project) async {
    final uid = context.read<AuthProvider>().uid;
    final isOwner = project.ownerUid == uid;
    final memberCount = project.memberUids.length;

    if (isOwner && memberCount > 1) {
      // Owner cannot leave while others are still in the project.
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(
              'Cannot Leave Project',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'You are the owner of "${project.name}" and there are still '
              '${memberCount - 1} other member${memberCount - 1 == 1 ? '' : 's'}. '
              'Transfer ownership to another member before leaving, or remove '
              'all other members first.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (isOwner && memberCount <= 1) {
      // Owner is sole member – offer to delete the project.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(
              'Delete Project?',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'You are the only member of "${project.name}". '
              'Leaving will permanently delete the project and all its data.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
      if (!mounted) return;
      final err = await context
          .read<ProjectsProvider>()
          .deleteProject(project.id);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Regular member – confirm then leave.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'Leave Project?',
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to leave "${project.name}"? '
            'You can rejoin with an invite link.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: cs.error, foregroundColor: cs.onError),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final err =
        await context.read<ProjectsProvider>().leaveProject(project.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have left the project.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  void _showInviteSheet(BuildContext context, GroupProject project) {
    final colorScheme = Theme.of(context).colorScheme;
    final link = 'homeworkhelper://project/${project.id}';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Invite to ${project.name}',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Share this QR code or link to invite others.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite link copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Prefer the live provider list so edits are reflected instantly.
    final provider = context.watch<ProjectsProvider>();
    final project = provider.projects
            .cast<GroupProject?>()
            .firstWhere((p) => p?.id == widget.projectId,
                orElse: () => null) ??
        _directProject;

    // ── Still waiting for Firestore ──────────────────────────────────────────
    if (project == null && _loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Text('Project',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error / not-found ────────────────────────────────────────────────────
    if (project == null) {
      final message = _error ?? 'Project not found.';
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          title: Text('Project',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_rounded,
                    size: 56, color: colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _ensureLoaded,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Project loaded ───────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          project.name,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Invite',
            onPressed: () => _showInviteSheet(context, project),
          ),
          PopupMenuButton<_ProjectAction>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (action) {
              if (action == _ProjectAction.leave) {
                _handleLeaveOrDelete(context, project);
              }
            },
            itemBuilder: (_) {
              final uid = context.read<AuthProvider>().uid;
              final isOwner = project.ownerUid == uid;
              final isSoleMember = project.memberUids.length <= 1;
              final label = (isOwner && isSoleMember)
                  ? 'Delete Project'
                  : (isOwner ? 'Leave / Delete…' : 'Leave Project');
              final icon = (isOwner && isSoleMember)
                  ? Icons.delete_forever_rounded
                  : Icons.exit_to_app_rounded;
              return [
                PopupMenuItem<_ProjectAction>(
                  value: _ProjectAction.leave,
                  child: Row(
                    children: [
                      Icon(icon,
                          color: Theme.of(context).colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Bulletin'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BulletinTab(projectId: project.id),
          _TasksTab(projectId: project.id, project: project),
        ],
      ),
    );
  }
}

// ── Bulletin Tab ──────────────────────────────────────────────────────────────

class _BulletinTab extends StatefulWidget {
  final String projectId;
  const _BulletinTab({required this.projectId});

  @override
  State<_BulletinTab> createState() => _BulletinTabState();
}

class _BulletinTabState extends State<_BulletinTab> {
  final _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final handle = auth.username ?? 'anonymous';
    await context.read<ProjectsProvider>().addPost(
          projectId: widget.projectId,
          authorHandle: handle,
          text: text,
        );
    _postController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stream =
        context.read<ProjectsProvider>().bulletinStream(widget.projectId);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<BulletinPost>>(
            stream: stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snap.data ?? [];
              if (posts.isEmpty) {
                return Center(
                  child: Text(
                    'No posts yet. Be the first!',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _PostCard(
                  post: posts[i],
                  colorScheme: colorScheme,
                ),
              );
            },
          ),
        ),
        // Compose bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Post an update…',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                onPressed: _post,
                style: IconButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final BulletinPost post;
  final ColorScheme colorScheme;
  const _PostCard({required this.post, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _kBlue.withAlpha(30),
                child: Text(
                  post.authorHandle.isNotEmpty
                      ? post.authorHandle[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kBlue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '@${post.authorHandle}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text(
                _formatTime(post.createdAt),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.text),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Tasks Tab ─────────────────────────────────────────────────────────────────

class _TasksTab extends StatefulWidget {
  final String projectId;
  final GroupProject project;
  const _TasksTab({required this.projectId, required this.project});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    await context
        .read<ProjectsProvider>()
        .addTask(projectId: widget.projectId, title: title);
    _taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stream =
        context.read<ProjectsProvider>().taskStream(widget.projectId);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ProjectTask>>(
            stream: stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snap.data ?? [];
              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    'No tasks yet. Add one below!',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TaskCard(
                  task: tasks[i],
                  projectId: widget.projectId,
                  colorScheme: colorScheme,
                ),
              );
            },
          ),
        ),
        // Add task bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add a task…',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add_rounded),
                onPressed: _addTask,
                style: IconButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ProjectTask task;
  final String projectId;
  final ColorScheme colorScheme;

  const _TaskCard({
    required this.task,
    required this.projectId,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: task.status == TaskStatus.done
            ? colorScheme.primaryContainer.withAlpha(80)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _StatusIcon(status: task.status, colorScheme: colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: task.status == TaskStatus.done
                    ? TextDecoration.lineThrough
                    : null,
                color: task.status == TaskStatus.done
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
          ),
          PopupMenuButton<TaskStatus>(
            initialValue: task.status,
            onSelected: (s) => context
                .read<ProjectsProvider>()
                .updateTaskStatus(
                    projectId: projectId, taskId: task.id, status: s),
            itemBuilder: (_) => TaskStatus.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(task.status).withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(task.status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return colorScheme.onSurfaceVariant;
      case TaskStatus.inProgress:
        return _kBlue;
      case TaskStatus.done:
        return colorScheme.primary;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final TaskStatus status;
  final ColorScheme colorScheme;
  const _StatusIcon({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.todo:
        return Icon(Icons.radio_button_unchecked_rounded,
            color: colorScheme.outlineVariant, size: 22);
      case TaskStatus.inProgress:
        return const Icon(Icons.timelapse_rounded, color: _kBlue, size: 22);
      case TaskStatus.done:
        return Icon(Icons.check_circle_rounded,
            color: colorScheme.primary, size: 22);
    }
  }
}

// ── Join Project Screen ───────────────────────────────────────────────────────

/// Shown when the user opens a `homeworkhelper://project/<projectId>` deep link.
///
/// Fetches the project info and lets the user join.
class JoinProjectScreen extends StatefulWidget {
  final String projectId;
  const JoinProjectScreen({super.key, required this.projectId});

  @override
  State<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends State<JoinProjectScreen> {
  GroupProject? _project;
  bool _loading = true;
  String? _error;
  bool _joining = false;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final p = await context
        .read<ProjectsProvider>()
        .getProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _project = p;
      _error = p == null ? 'This project does not exist or has been deleted.' : null;
      _loading = false;
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    final error = await context
        .read<ProjectsProvider>()
        .joinProject(widget.projectId);
    if (!mounted) return;
    setState(() => _joining = false);
    if (error == null) {
      setState(() => _joined = true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: widget.projectId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Join Project',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 64, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _kBlue.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.group_work_rounded,
                                color: _kBlue, size: 36),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _project!.name,
                            style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_project!.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _project!.description,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${_project!.memberUids.length} member${_project!.memberUids.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: (_joining || _joined) ? null : _join,
                              icon: _joining
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : _joined
                                      ? const Icon(Icons.check_rounded)
                                      : const Icon(Icons.group_add_rounded),
                              label: Text(
                                _joined ? 'Joined!' : 'Join Project',
                                style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _kBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
