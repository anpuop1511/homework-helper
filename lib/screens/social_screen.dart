import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import 'nfc_bump_screen.dart';
import 'public_profile_screen.dart';
import 'qr_scan_screen.dart';

/// Electric Blue — used for the "Add Friend" action to match the V2.3 design.
const _kElectricBlue = Color(0xFF007FFF);

/// The "Social Quad" tab – search for friends by @username, view pending
/// requests, and browse your accepted friends list.
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _handleController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  void _showMyQr(BuildContext context, String handle) {
    final colorScheme = Theme.of(context).colorScheme;
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
              '@$handle',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: 'homeworkhelper://profile/@$handle',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final myHandle = auth.username;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Social Quad',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Header ────────────────────────────────────────────────
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Social Quad',
                  style: GoogleFonts.lexend(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            FadeInDown(
              delay: const Duration(milliseconds: 60),
              duration: const Duration(milliseconds: 400),
              child: Text(
                'Study together, grow together.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            // ── Own @handle chip ──────────────────────────────────────
            if (myHandle != null && myHandle.isNotEmpty) ...[
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 90),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            myHandle,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── NFC Buddy Bump Button ─────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 80),
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NfcBumpScreen()),
                  ),
                  icon: const Icon(Icons.nfc_rounded, size: 20),
                  label: Text(
                    'Bump to Study ⚡',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kElectricBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Scan QR Button ────────────────────────────────────
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScanScreen()),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: Text(
                    'Scan Friend\'s QR',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Show My QR Button ─────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 120),
              duration: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: myHandle != null && myHandle.isNotEmpty
                      ? () => _showMyQr(context, myHandle)
                      : null,
                  icon: const Icon(Icons.qr_code_rounded, size: 20),
                  label: Text(
                    'Show My QR Code',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
              child: _SectionCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_add_rounded,
                            color: _kElectricBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add a Friend',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _handleController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: '@username',
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onSubmitted: (_) => _sendRequest(context),
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
                                  onPressed: () => _sendRequest(context),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kElectricBlue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(48, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  child:
                                      const Icon(Icons.send_rounded),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Pending Requests ──────────────────────────────────────
            if (social.pendingRequests.isNotEmpty) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 400),
                child: _SectionHeader(
                  icon: Icons.notifications_rounded,
                  label: 'Friend Requests',
                  badge: social.pendingRequests.length,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 10),
              ...social.pendingRequests.asMap().entries.map((entry) {
                final idx = entry.key;
                final req = entry.value;
                return FadeInLeft(
                  delay: Duration(milliseconds: 200 + idx * 60),
                  duration: const Duration(milliseconds: 350),
                  child: _RequestCard(
                    request: req,
                    colorScheme: colorScheme,
                    onAccept: () =>
                        context.read<SocialProvider>().acceptRequest(req),
                    onDecline: () =>
                        context.read<SocialProvider>().declineRequest(req),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // ── Friends List ──────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 220),
              duration: const Duration(milliseconds: 400),
              child: _SectionHeader(
                icon: Icons.group_rounded,
                label: 'Friends',
                badge: social.friends.length,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(height: 10),
            if (social.friends.isEmpty)
              FadeInUp(
                delay: const Duration(milliseconds: 280),
                duration: const Duration(milliseconds: 400),
                child: _EmptyFriendsCard(colorScheme: colorScheme),
              )
            else
              ...social.friends.asMap().entries.map((entry) {
                final idx = entry.key;
                final friend = entry.value;
                return FadeInLeft(
                  delay: Duration(milliseconds: 280 + idx * 60),
                  duration: const Duration(milliseconds: 350),
                  child: _FriendCard(
                    friend: friend,
                    colorScheme: colorScheme,
                    onRemove: () =>
                        context.read<SocialProvider>().removeFriend(friend.id),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;

  const _SectionCard({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

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
        color: colorScheme.secondaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              initial.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondaryContainer,
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
          IconButton.filledTonal(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Accept',
            onPressed: onAccept,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: friend.photoUrl != null && friend.photoUrl!.isNotEmpty
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.username.isNotEmpty
                      ? '@${friend.username}'
                      : (friend.name.isNotEmpty ? friend.name : 'Unknown user'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withAlpha(140),
          ),
          const SizedBox(height: 12),
          Text(
            'No friends yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
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
