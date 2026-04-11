import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';
import '../services/database_service.dart';

const _kElectricBlue = Color(0xFF007FFF);

/// Public profile screen for a user identified by @[handle].
///
/// Shows basic public fields and relationship actions:
///   - Add Friend (if allowed by privacy settings)
///   - Pending (if request already sent)
///   - Accept / Decline (if they sent a request to us)
///   - Private / Friends-only (if blocked by privacy settings)
class PublicProfileScreen extends StatefulWidget {
  final String handle;

  const PublicProfileScreen({super.key, required this.handle});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  String _status = 'none'; // 'none', 'request_sent', 'request_received', 'friends'
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String? _incomingRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _cleanHandle =>
      widget.handle.replaceFirst(RegExp(r'^@'), '').toLowerCase();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await DatabaseService.instance.getPublicProfile(_cleanHandle);
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _loading = false;
          _error = 'No user found with @$_cleanHandle';
        });
        return;
      }

      final auth = context.read<AuthProvider>();
      final currentUid = auth.uid;
      String status = 'none';
      String? incomingRequestId;

      if (currentUid != null && profile['uid'] != currentUid) {
        status = await DatabaseService.instance.checkRelationshipStatus(
          currentUid, profile['uid'] as String,
        );
        if (status == 'request_received') {
          // Find the request ID for accept/decline.
          try {
            final snap = await DatabaseService.instance.getPendingRequestFromUser(
              fromUid: profile['uid'] as String,
              toUid: currentUid,
            );
            incomingRequestId = snap;
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _status = status;
          _incomingRequestId = incomingRequestId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load profile. Check your connection.';
        });
      }
    }
  }

  Future<void> _addFriend() async {
    final auth = context.read<AuthProvider>();
    final social = context.read<SocialProvider>();
    if (auth.uid == null) return;
    setState(() => _actionLoading = true);
    final error = await social.sendFriendRequestByUsername(_cleanHandle);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (error == null) {
      setState(() => _status = 'request_sent');
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

  Future<void> _acceptRequest() async {
    if (_incomingRequestId == null || _profile == null) return;
    final social = context.read<SocialProvider>();
    setState(() => _actionLoading = true);
    try {
      final request = social.pendingRequests.firstWhere(
        (r) => r.fromUid == (_profile!['uid'] as String),
        orElse: () => throw Exception('Request not found'),
      );
      await social.acceptRequest(request);
      if (mounted) {
        setState(() {
          _status = 'friends';
          _actionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now friends with @$_cleanHandle! 🎉'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not accept request. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest() async {
    if (_incomingRequestId == null || _profile == null) return;
    final social = context.read<SocialProvider>();
    setState(() => _actionLoading = true);
    try {
      final request = social.pendingRequests.firstWhere(
        (r) => r.fromUid == (_profile!['uid'] as String),
        orElse: () => throw Exception('Request not found'),
      );
      await social.declineRequest(request);
      if (mounted) {
        setState(() {
          _status = 'none';
          _incomingRequestId = null;
          _actionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final isSelf = _profile != null && _profile!['uid'] == auth.uid;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          '@$_cleanHandle',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_rounded,
                              size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildProfile(context, colorScheme, isSelf),
      ),
    );
  }

  Widget _buildProfile(
      BuildContext context, ColorScheme colorScheme, bool isSelf) {
    final profile = _profile!;
    final displayName = (profile['name'] as String?)?.isNotEmpty == true
        ? profile['name'] as String
        : '@$_cleanHandle';
    final username = profile['username'] as String? ?? _cleanHandle;
    final level = profile['level'] as int? ?? 1;
    final totalXp = profile['xp'] as int? ?? 0;
    final streak = profile['streak'] as int? ?? 0;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final photoUrl = profile['photoUrl'] as String?;

    // Check privacy
    final profileVisibilityIndex = profile['profileVisibility'] as int? ?? 0;
    final friendRequestsPrivacyIndex =
        profile['friendRequestsPrivacy'] as int? ?? 0;
    final profileVisibility =
        ProfileVisibility.values[profileVisibilityIndex.clamp(
            0, ProfileVisibility.values.length - 1)];
    final friendRequestsPrivacy =
        FriendRequestsPrivacy.values[friendRequestsPrivacyIndex.clamp(
            0, FriendRequestsPrivacy.values.length - 1)];

    // Determine if profile is visible
    final bool isProfileVisible = isSelf ||
        profileVisibility == ProfileVisibility.public ||
        (profileVisibility == ProfileVisibility.friendsOnly &&
            _status == 'friends');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // ── Avatar ────────────────────────────────────────────────────
        FadeIn(
          duration: const Duration(milliseconds: 400),
          child: Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      initial,
                      style: GoogleFonts.lexend(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Name & Handle ─────────────────────────────────────────────
        FadeInDown(
          delay: const Duration(milliseconds: 80),
          duration: const Duration(milliseconds: 350),
          child: Column(
            children: [
              Text(
                isProfileVisible ? displayName : '@$_cleanHandle',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Stats (visible if profile is public / friends-only and friends) ─
        if (isProfileVisible) ...[
          FadeInUp(
            delay: const Duration(milliseconds: 120),
            duration: const Duration(milliseconds: 350),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  label: 'Level $level',
                  colorScheme: colorScheme,
                ),
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '$streak day streak',
                  colorScheme: colorScheme,
                ),
                _StatChip(
                  icon: Icons.bolt_rounded,
                  label: '$totalXp XP',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Relationship action ───────────────────────────────────────
        if (!isSelf)
          FadeInUp(
            delay: const Duration(milliseconds: 160),
            duration: const Duration(milliseconds: 350),
            child: _buildActionButton(
              colorScheme,
              profileVisibility,
              friendRequestsPrivacy,
            ),
          ),

        if (isSelf) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'This is your profile.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    ColorScheme colorScheme,
    ProfileVisibility profileVisibility,
    FriendRequestsPrivacy friendRequestsPrivacy,
  ) {
    if (profileVisibility == ProfileVisibility.private) {
      return _PrivacyBanner(
        message: 'This profile is private.',
        colorScheme: colorScheme,
      );
    }

    if (_status == 'friends') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              'Friends',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_status == 'request_sent') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded,
                color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Request Pending',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_status == 'request_received') {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _actionLoading ? null : _acceptRequest,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(
                'Accept',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _kElectricBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _actionLoading ? null : _declineRequest,
              icon: const Icon(Icons.close_rounded),
              label: Text(
                'Decline',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    // status == 'none'
    if (friendRequestsPrivacy == FriendRequestsPrivacy.nobody) {
      return _PrivacyBanner(
        message: 'This user is not accepting friend requests.',
        colorScheme: colorScheme,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _actionLoading ? null : _addFriend,
        icon: _actionLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded),
        label: Text(
          'Add Friend',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _kElectricBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _StatChip(
      {required this.icon, required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;

  const _PrivacyBanner(
      {required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
