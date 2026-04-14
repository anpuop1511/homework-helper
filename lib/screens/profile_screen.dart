import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/assignments_provider.dart';
import '../services/database_service.dart';
import '../widgets/squircle_avatar.dart';
import 'season_shop_screen.dart';
import 'settings_screen.dart';
import 'username_screen.dart';

/// The user profile screen showing gamification stats:
/// level, XP progress bar, study streak, and assignment summary.
///
/// Redesigned for Android 16 / Material 3 Expressive style.
/// V2.3: Squircle avatar, @username display, profile photo picker, share link.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;
  Uint8List? _localPhotoBytes;

  Future<void> _pickPhoto() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _uploadingPhoto = true;
      _localPhotoBytes = bytes;
    });

    try {
      await DatabaseService.instance.uploadProfilePhoto(uid, bytes);
    } catch (_) {
      // Upload failed — keep the local preview.
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _shareInviteLink(String identifier) {
    final link = 'https://homework-helper-web-dun.vercel.app/invite/${Uri.encodeComponent(identifier)}';
    SharePlus.instance.share(
      ShareParams(
        text: 'Add me on Homework Helper! Tap to send a friend request: $link',
        subject: 'Study with me on Homework Helper 📚',
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    String currentDisplayName,
    String currentBio,
  ) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    final nameCtrl = TextEditingController(text: currentDisplayName);
    final bioCtrl = TextEditingController(text: currentBio);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others a bit about yourself…',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final newName = nameCtrl.text.trim();
      final newBio = bioCtrl.text.trim();
      if (newName.isEmpty) return;
      try {
        await DatabaseService.instance.updateProfile(uid, newName, newBio);
        if (mounted) {
          context.read<UserProvider>().setName(newName);
          context.read<UserProvider>().setBio(newBio);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<UserProvider>();
    final assignments = context.watch<AssignmentsProvider>();
    final auth = context.watch<AuthProvider>();

    final completedCount =
        assignments.assignments.where((a) => a.isCompleted).length;
    final totalCount = assignments.assignments.length;

    final displayName =
        user.name.isNotEmpty ? user.name : (auth.email?.split('@').first ?? '');
    final username = auth.username;
    final photoUrl = auth.currentUser?.photoURL;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Header row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'My Profile',
                style: GoogleFonts.lexend(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // ── Avatar + Name ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      SquircleAvatar(
                        radius: 50,
                        initial: displayName,
                        photoUrl: photoUrl,
                        localPhotoBytes: _localPhotoBytes,
                      ),
                      if (_uploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius:
                                  BorderRadius.circular(50 * 0.55),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      if (auth.isSignedIn)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: colorScheme.surface, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // @username display (tappable to change).
                  if (username != null && username.isNotEmpty)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const UsernameScreen(allowSkip: true)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '@$username',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  if (user.activeNameplate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _NameplateDisplay(nameplate: user.activeNameplate),
                  ],
                  Text(
                    'Level ${user.level} Scholar',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (auth.isSignedIn) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(
                        context,
                        displayName,
                        user.bio,
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Share Invite Link ─────────────────────────────────────
            if (auth.isSignedIn) ...[
              Builder(
                builder: (context) {
                  final shareIdentifier =
                      (username != null && username.isNotEmpty)
                          ? username
                          : auth.email;
                  if (shareIdentifier == null || shareIdentifier.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareInviteLink(shareIdentifier),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            'Share Invite Link',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],

            // ── Level + XP Card ───────────────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${user.level}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${user.xp} / ${user.xpForNextLevel} XP',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: user.levelProgress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            LinearProgressIndicator(
                          value: value,
                          minHeight: 14,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user.xpForNextLevel - user.xp} XP until Level ${user.level + 1}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 20),
                  // Coin balance row
                  Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${user.coins} Coins',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Battle Pass Tier ${user.seasonTier}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats Row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '${user.streak}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          user.streak == 1 ? 'Day Streak' : 'Day Streak 🔥',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '$completedCount',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    colorScheme: colorScheme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          '${user.totalXp}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Total XP',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Assignment Progress Card ──────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment Progress',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount of $totalCount tasks done',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        totalCount > 0
                            ? '${((completedCount / totalCount) * 100).round()}%'
                            : '0%',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalCount > 0
                          ? completedCount / totalCount
                          : 0,
                      minHeight: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.tertiary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── How XP is Earned ──────────────────────────────────────
            _StatCard(
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Earn XP',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _XpRow(
                    emoji: '✅',
                    label: 'Complete an assignment',
                    xp: '+25 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 8),
                  _XpRow(
                    emoji: '🍅',
                    label: 'Finish a Focus Timer session',
                    xp: '+15 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 8),
                  _XpRow(
                    emoji: '🔥',
                    label: 'Keep your daily streak',
                    xp: '+10 XP',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Sign Out ──────────────────────────────────────────────
            if (auth.isSignedIn)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _StatCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;

  const _StatCard({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _XpRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String xp;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _XpRow({
    required this.emoji,
    required this.label,
    required this.xp,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: textTheme.bodyMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            xp,
            style: GoogleFonts.outfit(
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

/// Displays the user's active nameplate with visual flair.
class _NameplateDisplay extends StatefulWidget {
  final String nameplate;
  const _NameplateDisplay({required this.nameplate});

  @override
  State<_NameplateDisplay> createState() => _NameplateDisplayState();
}

class _NameplateDisplayState extends State<_NameplateDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAnimated =
        widget.nameplate == 'animated_golden_cherry_blossom';

    if (isAnimated) {
      return AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF69B4)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700)
                    .withAlpha((_glowAnim.value * 180).toInt()),
                blurRadius: 12 * _glowAnim.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '✨ ${widget.nameplate.replaceAll('_', ' ')}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SeasonShopScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: colorScheme.tertiary.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.nameplate,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded,
                size: 12, color: colorScheme.onTertiaryContainer),
          ],
        ),
      ),
    );
  }
}
