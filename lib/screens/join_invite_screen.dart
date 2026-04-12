import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import 'public_profile_screen.dart';

/// Shown when the user opens a `homeworkhelper://invite/<inviteId>` deep link.
///
/// The inviteId for social invites is the username/handle of the person who
/// generated the QR code. This screen lets the user send a friend request to
/// that person or view their public profile.
class JoinInviteScreen extends StatefulWidget {
  /// The invite identifier extracted from the deep link path.
  ///
  /// For social profile invites this is the @handle (without the '@' prefix).
  final String inviteId;

  const JoinInviteScreen({super.key, required this.inviteId});

  @override
  State<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends State<JoinInviteScreen> {
  bool _loading = false;
  String? _error;
  bool _sent = false;

  Future<void> _sendRequest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final social = context.read<SocialProvider>();
    // Remove any leading '@' that might be present in the invite ID.
    final handle = widget.inviteId.startsWith('@')
        ? widget.inviteId.substring(1)
        : widget.inviteId;
    final error = await social.sendFriendRequestByUsername(handle);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final handle = widget.inviteId.startsWith('@')
        ? widget.inviteId.substring(1)
        : widget.inviteId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Friend Invite',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF007FFF).withAlpha(30),
                  child: Text(
                    handle.isNotEmpty ? handle[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF007FFF),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '@$handle',
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'wants to connect on Homework Helper',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_sent)
                  Column(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: colorScheme.primary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Friend request sent!',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to Social'),
                      ),
                    ],
                  )
                else ...[
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _sendRequest,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: Text(
                        'Send Friend Request',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF007FFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(handle: handle),
                        ),
                      ),
                      icon: const Icon(Icons.person_rounded),
                      label: Text(
                        'View Profile',
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
