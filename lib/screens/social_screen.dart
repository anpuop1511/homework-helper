import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/social_provider.dart';
import '../widgets/nameplate_widget.dart';
import 'group_projects_screen.dart';
import 'nfc_bump_screen.dart';
import 'public_profile_screen.dart';
import 'qr_scan_screen.dart';

/// Electric Blue — used for action tiles to match the V2.3 design.
const _kElectricBlue = Color(0xFF007FFF);

/// The "Social Quad" tab – Quick-Settings–inspired tile panel, pending
/// requests, and the friends list.
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _handleController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  void _showMyQr(BuildContext context, String identifier, {bool isEmail = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use an encoded invite URL that works for both username and email.
    final qrData = 'https://homework-helper-web-dun.vercel.app/invite/${Uri.encodeComponent(identifier)}';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
              'My QR Code',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEmail ? identifier : '@$identifier',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (isEmail)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Using email as fallback (no username set)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 16),
            Text(
              'Friends can scan this to add you.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context) async {
    final handle = _handleController.text.trim();
    if (handle.isEmpty) return;

    setState(() => _searching = true);
    final social = context.read<SocialProvider>();
    final error = await social.sendFriendRequestByUsername(handle);
    if (!mounted) return;
    setState(() => _searching = false);

    if (error == null) {
      _handleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Friend request sent! 🎉'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  /// Shows the Add-Friend bottom sheet (search by @username).
  void _showAddFriendSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border:
                Border(top: BorderSide(color: colorScheme.outlineVariant)),
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
                'Add a Friend',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _handleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '@username or email',
                        prefixIcon:
                            const Icon(Icons.alternate_email_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onSubmitted: (_) {
                        Navigator.pop(context);
                        _sendRequest(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _searching
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendRequest(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _kElectricBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(Icons.send_rounded),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog that accepts a project code/link and joins the project.
  void _showJoinProjectSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final codeController = TextEditingController();
    bool joining = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                            // Extract project ID from deep-link or bare ID.
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
                                  content: const Text(
                                      'Joined project! 🎉'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                ),
                              );
                              // Navigate into the project.
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.usernameLoaded) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final myHandle = auth.username;
    final requestCount = social.pendingRequests.length;
    final pendingCount = social.sentRequests.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kElectricBlue.withAlpha(22),
                colorScheme.primaryContainer.withAlpha(35),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kElectricBlue.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                color: _kElectricBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Social Quad',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _kElectricBlue.withAlpha(28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kElectricBlue.withAlpha(80), width: 1),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          labelColor: _kElectricBlue,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.group_rounded),
              text: 'Friends',
            ),
            Tab(
              child: _BadgeTab(
                icon: Icons.notifications_rounded,
                label: 'Requests',
                count: requestCount,
                colorScheme: colorScheme,
              ),
            ),
            Tab(
              child: _BadgeTab(
                icon: Icons.schedule_rounded,
                label: 'Pending',
                count: pendingCount,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Own @handle chip + web banner ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kIsWeb && (myHandle == null || myHandle.isEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withAlpha(200),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.tertiary.withAlpha(100)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18,
                            color: colorScheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Web handle sync is currently bugged '
                            '(email QR fallback works).',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (myHandle != null && myHandle.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kElectricBlue.withAlpha(35),
                          colorScheme.primaryContainer.withAlpha(180),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kElectricBlue.withAlpha(70)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alternate_email_rounded,
                          size: 14,
                          color: _kElectricBlue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          myHandle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kElectricBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Quick Actions Panel ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _QuickActionsGrid(
              colorScheme: colorScheme,
              onAddFriend: () => _showAddFriendSheet(context),
              onScanQr: () {
                if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'QR scanning is not supported on web. '
                        'Share your profile link instead.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScanScreen()),
                );
              },
              onMyQr: (myHandle != null && myHandle.isNotEmpty) ||
                      (auth.email?.isNotEmpty == true)
                  ? () {
                      final identifier =
                          (myHandle != null && myHandle.isNotEmpty)
                              ? myHandle!
                              : auth.email!;
                      _showMyQr(
                        context,
                        identifier,
                        isEmail: myHandle == null || myHandle.isEmpty,
                      );
                    }
                  : null,
              onNfcBump: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NfcBumpScreen()),
              ),
              onCreateProject: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GroupProjectsScreen()),
              ),
              onJoinProject: () => _showJoinProjectSheet(context),
            ),
          ),

          // ── Tab content ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Friends
                _buildFriendsTab(context, colorScheme, social),
                // Tab 1 — Requests
                _buildRequestsTab(context, colorScheme, social),
                // Tab 2 — Pending
                _buildPendingTab(context, colorScheme, social),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab builders ──────────────────────────────────────────────────────────

  Widget _buildFriendsTab(
      BuildContext context, ColorScheme colorScheme, SocialProvider social) {
    if (social.friends.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _EmptyFriendsCard(colorScheme: colorScheme),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: social.friends.length,
      itemBuilder: (_, idx) {
        final friend = social.friends[idx];
        return FadeInLeft(
          delay: Duration(milliseconds: idx * 50),
          duration: const Duration(milliseconds: 300),
          child: _FriendCard(
            friend: friend,
            colorScheme: colorScheme,
            onRemove: () =>
                context.read<SocialProvider>().removeFriend(friend.id),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(
      BuildContext context, ColorScheme colorScheme, SocialProvider social) {
    if (social.pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kElectricBlue.withAlpha(22),
                      colorScheme.primaryContainer.withAlpha(60),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_none_rounded,
                    size: 48,
                    color: _kElectricBlue.withAlpha(200)),
              ),
              const SizedBox(height: 16),
              Text(
                'No incoming requests',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'When someone sends you a friend request it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: social.pendingRequests.length,
      itemBuilder: (_, idx) {
        final req = social.pendingRequests[idx];
        return FadeInLeft(
          delay: Duration(milliseconds: idx * 60),
          duration: const Duration(milliseconds: 350),
          child: _RequestCard(
            request: req,
            colorScheme: colorScheme,
            onAccept: () {
              final handle = req.fromUsername.isNotEmpty
                  ? '@${req.fromUsername}'
                  : req.fromName.isNotEmpty
                      ? req.fromName
                      : 'them';
              context.read<SocialProvider>().acceptRequest(req).then((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You are now friends with $handle! 🎉'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  );
                }
              }).catchError((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Request no longer available — it may have been cancelled.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
            onDecline: () =>
                context.read<SocialProvider>().declineRequest(req),
          ),
        );
      },
    );
  }

  Widget _buildPendingTab(
      BuildContext context, ColorScheme colorScheme, SocialProvider social) {
    if (social.sentRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary.withAlpha(22),
                      colorScheme.tertiaryContainer.withAlpha(80),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_rounded,
                    size: 48,
                    color: colorScheme.tertiary.withAlpha(200)),
              ),
              const SizedBox(height: 16),
              Text(
                'No pending requests',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sent friend requests waiting for a response will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: social.sentRequests.length,
      itemBuilder: (_, idx) {
        final req = social.sentRequests[idx];
        return FadeInLeft(
          delay: Duration(milliseconds: idx * 60),
          duration: const Duration(milliseconds: 350),
          child: _PendingRequestCard(
            request: req,
            colorScheme: colorScheme,
            onCancel: () =>
                context.read<SocialProvider>().cancelSentRequest(req),
          ),
        );
      },
    );
  }
}

// ── Badge tab label ───────────────────────────────────────────────────────────

/// A tab label that shows an icon, text, and an optional numeric badge.
class _BadgeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final ColorScheme colorScheme;

  const _BadgeTab({
    required this.icon,
    required this.label,
    required this.count,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onError,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Pending (sent) request card ───────────────────────────────────────────────

/// Card shown in the Pending tab for an outgoing friend request.
class _PendingRequestCard extends StatelessWidget {
  final SentRequest request;
  final ColorScheme colorScheme;
  final VoidCallback onCancel;

  const _PendingRequestCard({
    required this.request,
    required this.colorScheme,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final displayHandle = request.displayHandle;
    final initial = displayHandle.isNotEmpty ? displayHandle[0] : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(160)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(80),
                  colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 21,
              backgroundColor:
                  colorScheme.secondaryContainer.withAlpha(180),
              child: Text(
                initial.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayHandle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 11,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      'Awaiting response',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────

/// Android Quick-Settings–inspired 2-column tile grid for Social quick actions.
class _QuickActionsGrid extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onAddFriend;
  final VoidCallback onScanQr;
  final VoidCallback? onMyQr;
  final VoidCallback onNfcBump;
  final VoidCallback onCreateProject;
  final VoidCallback onJoinProject;

  const _QuickActionsGrid({
    required this.colorScheme,
    required this.onAddFriend,
    required this.onScanQr,
    required this.onMyQr,
    required this.onNfcBump,
    required this.onCreateProject,
    required this.onJoinProject,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(
        icon: Icons.person_add_rounded,
        label: 'Add Friend',
        color: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
        onTap: onAddFriend,
      ),
      _TileData(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan QR',
        color: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
        onTap: onScanQr,
      ),
      _TileData(
        icon: Icons.qr_code_rounded,
        label: 'My QR',
        color: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
        onTap: onMyQr,
        disabled: onMyQr == null,
      ),
      if (!kIsWeb)
        _TileData(
          icon: Icons.nfc_rounded,
          label: 'NFC Bump',
          color: const Color(0xFF007FFF).withAlpha(30),
          foreground: const Color(0xFF007FFF),
          onTap: onNfcBump,
        ),
      _TileData(
        icon: Icons.group_work_rounded,
        label: 'Current Projects',
        color: colorScheme.surfaceContainerHigh,
        foreground: colorScheme.onSurface,
        onTap: onCreateProject,
      ),
      _TileData(
        icon: Icons.login_rounded,
        label: 'Join Project',
        color: const Color(0xFF1976D2).withAlpha(30),
        foreground: const Color(0xFF1976D2),
        onTap: onJoinProject,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // On wider screens the tiles would become disproportionately large;
        // cap the available width and use more columns when space allows.
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = availableWidth >= 500 ? 3 : 2;
        // Keep tiles square-ish: wider screens need a larger ratio because
        // each tile is narrower relative to its fixed-height content.
        final aspectRatio = crossAxisCount == 3 ? 1.6 : 1.55;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: tiles.length,
          itemBuilder: (_, i) => _QsTile(data: tiles[i]),
        );
      },
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;
  final bool disabled;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.onTap,
    this.disabled = false,
  });
}

class _QsTile extends StatelessWidget {
  final _TileData data;
  const _QsTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final active = !data.disabled;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: active
            ? LinearGradient(
                colors: [
                  data.color,
                  Color.lerp(data.color, data.foreground, 0.14)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : data.color.withAlpha(60),
        boxShadow: active
            ? [
                BoxShadow(
                  color: data.foreground.withAlpha(45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: active ? data.onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:
                        data.foreground.withAlpha(active ? 32 : 16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    data.icon,
                    color: active
                        ? data.foreground
                        : data.foreground.withAlpha(100),
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  data.label,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: active
                        ? data.foreground
                        : data.foreground.withAlpha(100),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final ColorScheme colorScheme;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.badge,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        if (badge > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FriendRequest request;
  final ColorScheme colorScheme;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.colorScheme,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer @username, then display name, then "Unknown user".
    final displayHandle = request.fromUsername.isNotEmpty
        ? '@${request.fromUsername}'
        : (request.fromName.isNotEmpty
            ? request.fromName
            : 'Unknown user');
    final initial = displayHandle.isNotEmpty ? displayHandle[0] : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer.withAlpha(130),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _kElectricBlue.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: _kElectricBlue.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _kElectricBlue.withAlpha(180),
                  colorScheme.primary.withAlpha(120),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                initial.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayHandle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (request.fromUsername.isNotEmpty &&
                    request.fromName.isNotEmpty)
                  Text(
                    request.fromName,
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Accept button with gradient
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007FFF), Color(0xFF0050C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _kElectricBlue.withAlpha(90),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAccept,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Decline',
            onPressed: onDecline,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.friend,
    required this.colorScheme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: friend.username.isNotEmpty
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PublicProfileScreen(handle: friend.username),
                ),
              )
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient ring based on passType
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: friend.passType == 'premium'
                    ? const [Color(0xFFFFD700), Color(0xFFFF8C00)]
                    : friend.passType == 'plus'
                        ? const [Color(0xFF007FFF), Color(0xFF4FC3F7)]
                        : [
                            colorScheme.primary.withAlpha(100),
                            colorScheme.primaryContainer,
                          ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  friend.photoUrl != null && friend.photoUrl!.isNotEmpty
                      ? NetworkImage(friend.photoUrl!)
                      : null,
              child: friend.photoUrl == null || friend.photoUrl!.isEmpty
                  ? Text(
                      friend.initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username / display name — wrapped in nameplate if equipped.
                Row(
                  children: [
                    if (friend.activeNameplate.isNotEmpty)
                      Flexible(
                        child: NameplateWidget(
                          username: friend.username.isNotEmpty
                              ? '@${friend.username}'
                              : (friend.name.isNotEmpty ? friend.name : 'Unknown user'),
                          nameplateId: friend.activeNameplate,
                          fontSize: 12,
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          friend.username.isNotEmpty
                              ? '@${friend.username}'
                              : (friend.name.isNotEmpty ? friend.name : 'Unknown user'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Pass-type icon
                    if (passTypeIcon(friend.passType).isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        passTypeIcon(friend.passType),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: friend.passType == 'premium'
                              ? const Color(0xFFB8860B)
                              : const Color(0xFF007FFF),
                        ),
                      ),
                    ],
                    // Equipped badge
                    if (badgeEmoji(friend.equippedBadge).isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        badgeEmoji(friend.equippedBadge),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                if (friend.username.isNotEmpty && friend.name.isNotEmpty)
                  Text(
                    friend.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Level ${friend.level} · ${friend.totalXp} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Level badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lvl ${friend.level}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant, size: 20),
            onPressed: () => _showRemoveDialog(context),
          ),
        ],
      ),
    ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    final displayName = friend.username.isNotEmpty
        ? '@${friend.username}'
        : (friend.name.isNotEmpty ? friend.name : 'this user');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove $displayName from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFriendsCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyFriendsCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kElectricBlue.withAlpha(12),
            colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kElectricBlue.withAlpha(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kElectricBlue.withAlpha(22),
                  colorScheme.primaryContainer.withAlpha(80),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_outlined,
              size: 48,
              color: _kElectricBlue.withAlpha(200),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No friends yet',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search by @username above to add friends\nor use "Bump to Study" to connect instantly!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
