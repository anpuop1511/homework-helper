import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/security_provider.dart';
import '../providers/social_provider.dart';

/// The "Bump to Study" NFC screen.
///
/// On Android/iOS: pulses a glowing Electric Blue animation while in bump mode.
///   - One phone writes its @username + UID to the NFC tag.
///   - The other phone reads it and sends a Firestore friend request.
///
/// On Web: falls back to a QR code with the same glow design.
class NfcBumpScreen extends StatefulWidget {
  const NfcBumpScreen({super.key});

  @override
  State<NfcBumpScreen> createState() => _NfcBumpScreenState();
}

class _NfcBumpScreenState extends State<NfcBumpScreen>
    with TickerProviderStateMixin {
  bool _nfcAvailable = false;
  bool _bumping = false;
  String? _statusMessage;
  bool _success = false;

  // Electric Blue for the glow effect.
  static const _electricBlue = Color(0xFF007FFF);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    if (!kIsWeb) {
      _checkNfc();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (!kIsWeb && _bumping) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  Future<void> _checkNfc() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) setState(() => _nfcAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _nfcAvailable = false);
    }
  }

  Future<void> _startBumping() async {
    // ── Biometric gate (if enabled in Security settings) ─────────────
    final security = context.read<SecurityProvider>();
    if (security.isBioNfcEnabled) {
      final ok = await security.authenticate(
          reason: 'Verify your identity to start NFC Bump');
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verification failed.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
        return;
      }
    }

    setState(() {
      _bumping = true;
      _statusMessage = 'Hold phones back-to-back…';
      _success = false;
    });

    final auth = context.read<AuthProvider>();
    final uid = auth.uid ?? '';
    final username = auth.username ?? '';

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // Try to write first (so the phone with an active write session
          // acts as the "sender").  Fall back to reading if write fails.
          try {
            final ndef = Ndef.from(tag);
            if (ndef != null && ndef.isWritable) {
              // Write our info to the tag.
              final payload = '$uid:$username';
              final record = NdefRecord.createText(payload);
              await ndef.write(NdefMessage([record]));
              await NfcManager.instance.stopSession();
              _onSuccess('Link written! Tell your friend to tap now.');
              return;
            }
          } catch (_) {
            // Writing failed – fall through to read.
          }

          // Read the tag (other phone's data).
          try {
            final ndef = Ndef.from(tag);
            if (ndef != null) {
              final message = await ndef.read();
              for (final record in message.records) {
                final text = String.fromCharCodes(record.payload.skip(3));
                final parts = text.split(':');
                if (parts.length >= 2) {
                  final friendUsername = parts[1];
                  final social = context.read<SocialProvider>();
                  await social.sendFriendRequestByUsername(friendUsername);
                  await NfcManager.instance.stopSession();
                  _onSuccess('Friend request sent to @$friendUsername! 🎉');
                  return;
                }
              }
            }
            await NfcManager.instance.stopSession();
            _onError('Could not read the tag. Please try again.');
          } catch (_) {
            await NfcManager.instance.stopSession();
            _onError('Could not read the tag. Please try again.');
          }
        },
        onError: (e) async {
          _onError('NFC error. Please try again.');
        },
      );
    } catch (_) {
      _onError('Could not start NFC. Please check your device settings.');
    }
  }

  void _onSuccess(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _bumping = false;
      _success = true;
      _statusMessage = message;
    });
  }

  void _onError(String message) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _bumping = false;
      _success = false;
      _statusMessage = message;
    });
  }

  void _stopBumping() {
    if (_bumping) {
      NfcManager.instance.stopSession();
    }
    setState(() {
      _bumping = false;
      _statusMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final username = auth.username ?? auth.currentUser?.displayName ?? 'you';
    final uid = auth.uid ?? '';
    final profileUrl = 'https://homeworkhelper.app/invite/@$username';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Bump to Study',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Glow orb ────────────────────────────────────────────
              _GlowOrb(
                pulseAnim: _pulseAnim,
                bumping: _bumping,
                success: _success,
                electricBlue: _electricBlue,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 28),

              // ── Status message ───────────────────────────────────────
              if (_statusMessage != null)
                FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _success
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _success
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── NFC / QR section ─────────────────────────────────────
              if (kIsWeb)
                _WebQrSection(
                  profileUrl: profileUrl,
                  pulseAnim: _pulseAnim,
                  electricBlue: _electricBlue,
                  colorScheme: colorScheme,
                )
              else
                _NfcSection(
                  nfcAvailable: _nfcAvailable,
                  bumping: _bumping,
                  electricBlue: _electricBlue,
                  colorScheme: colorScheme,
                  onStart: _startBumping,
                  onStop: _stopBumping,
                  // QR fallback when NFC not available on mobile.
                  profileUrl: profileUrl,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Animation<double> pulseAnim;
  final bool bumping;
  final bool success;
  final Color electricBlue;
  final ColorScheme colorScheme;

  const _GlowOrb({
    required this.pulseAnim,
    required this.bumping,
    required this.success,
    required this.electricBlue,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        final glowRadius =
            bumping ? 24.0 + pulseAnim.value * 32.0 : (success ? 24.0 : 8.0);
        final glowOpacity =
            bumping ? 0.25 + pulseAnim.value * 0.35 : (success ? 0.4 : 0.1);
        final orbColor = bumping || success ? electricBlue : colorScheme.primary;

        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: orbColor.withAlpha((glowOpacity * 255).round()),
                blurRadius: glowRadius,
                spreadRadius: glowRadius * 0.5,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  orbColor.withAlpha(bumping ? 200 : 150),
                  orbColor.withAlpha(bumping ? 100 : 60),
                ],
              ),
            ),
            child: Icon(
              success
                  ? Icons.check_rounded
                  : (bumping
                      ? Icons.nfc_rounded
                      : Icons.nfc_rounded),
              size: 64,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _NfcSection extends StatelessWidget {
  final bool nfcAvailable;
  final bool bumping;
  final Color electricBlue;
  final ColorScheme colorScheme;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final String profileUrl;

  const _NfcSection({
    required this.nfcAvailable,
    required this.bumping,
    required this.electricBlue,
    required this.colorScheme,
    required this.onStart,
    required this.onStop,
    required this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (!nfcAvailable) {
      // NFC not available — show QR as fallback.
      return _WebQrSection(
        profileUrl: profileUrl,
        pulseAnim: const AlwaysStoppedAnimation(0),
        electricBlue: electricBlue,
        colorScheme: colorScheme,
        label: 'NFC not available — share your QR instead',
      );
    }

    return Column(
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 350),
          child: Text(
            bumping
                ? 'Hold phones back-to-back to connect ✨'
                : 'Tap the button and hold your phones together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: bumping
              ? OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop Bumping'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.nfc_rounded),
                  label: const Text('Start Bumping'),
                  style: FilledButton.styleFrom(
                    backgroundColor: electricBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Or share your QR code instead',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        _QrCard(profileUrl: profileUrl, colorScheme: colorScheme),
      ],
    );
  }
}

class _WebQrSection extends StatelessWidget {
  final String profileUrl;
  final Animation<double> pulseAnim;
  final Color electricBlue;
  final ColorScheme colorScheme;
  final String? label;

  const _WebQrSection({
    required this.profileUrl,
    required this.pulseAnim,
    required this.electricBlue,
    required this.colorScheme,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label ?? 'Share your QR code to add friends instantly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: electricBlue
                      .withAlpha(((0.15 + pulseAnim.value * 0.25) * 255).round()),
                  blurRadius: 16 + pulseAnim.value * 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
          child: _QrCard(profileUrl: profileUrl, colorScheme: colorScheme),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  final String profileUrl;
  final ColorScheme colorScheme;

  const _QrCard({required this.profileUrl, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: QrImageView(
        data: profileUrl,
        version: QrVersions.auto,
        size: 200,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}
