import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'group_projects_screen.dart';
import 'join_invite_screen.dart';
import 'public_profile_screen.dart';

/// QR code scan screen.
///
/// Parses deep links encoded in QR codes and navigates to the correct screen:
///   - `homeworkhelper://profile/@handle` → [PublicProfileScreen]
///   - `homeworkhelper://u/handle`         → [PublicProfileScreen]
///   - `homeworkhelper://invite/<handle>`  → [JoinInviteScreen]
///   - `homeworkhelper://project/<id>`     → [JoinProjectScreen]
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null) return;

    final dest = _parseLink(raw);
    if (dest == null) return;

    setState(() => _scanned = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => dest),
    );
  }

  /// Parses a QR value string and returns the appropriate destination widget.
  ///
  /// Supported formats:
  ///   - `https://homework-helper-web-dun.vercel.app/project/<projectId>`
  ///   - `https://homework-helper-web-dun.vercel.app/invite/<handle>`
  ///   - `https://homework-helper-web-dun.vercel.app/u/<handle>`
  ///   - `homeworkhelper://profile/@handle` / `homeworkhelper://u/handle`
  ///   - `homeworkhelper://invite/<handle>`
  ///   - `homeworkhelper://project/<projectId>`
  ///   - bare `@handle` or `handle`
  static Widget? _parseLink(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.parse(trimmed);

      // Handle HTTPS Vercel deep links.
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host == 'homework-helper-web-dun.vercel.app') {
        final segments = uri.pathSegments;
        final type = segments.isNotEmpty ? segments[0] : '';
        final id = segments.length > 1
            ? segments[1].replaceFirst(RegExp(r'^@'), '')
            : '';

        switch (type) {
          case 'project':
            if (id.isNotEmpty) {
              return JoinProjectScreen(projectId: id);
            }
            break;
          case 'invite':
            if (id.isNotEmpty) {
              return JoinInviteScreen(inviteId: id);
            }
            break;
          case 'u':
            if (id.isNotEmpty) {
              return PublicProfileScreen(handle: id);
            }
            break;
        }
      }

      if (uri.scheme == 'homeworkhelper') {
        final host = uri.host;
        final segments = uri.pathSegments;
        final id = segments.isNotEmpty
            ? segments.first.replaceFirst(RegExp(r'^@'), '')
            : '';

        switch (host) {
          case 'project':
            if (id.isNotEmpty) {
              return JoinProjectScreen(projectId: id);
            }
            break;
          case 'invite':
            if (id.isNotEmpty) {
              return JoinInviteScreen(inviteId: id);
            }
            break;
          case 'profile':
          case 'u':
            if (id.isNotEmpty) {
              return PublicProfileScreen(handle: id);
            }
            break;
        }
      }
    } catch (_) {}

    // Bare @handle or handle — treat as a profile link.
    final bare = trimmed.replaceFirst(RegExp(r'^@'), '');
    if (RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(bare)) {
      return PublicProfileScreen(handle: bare);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, __) {
                final torchIcon =
                    state.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded;
                return Icon(torchIcon, color: Colors.white);
              },
            ),
            tooltip: 'Toggle torch',
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with cutout hint.
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Point at a friend\'s QR code to open their profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 14,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
