import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'public_profile_screen.dart';

/// QR code scan screen.
///
/// Parses handles from deep links in the formats:
///   - `homeworkhelper://profile/@handle`
///   - `homeworkhelper://u/handle`
///   - `homeworkhelper://profile/handle`
///
/// On a successful scan, navigates to [PublicProfileScreen].
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

    final handle = _parseHandle(raw);
    if (handle == null) return;

    setState(() => _scanned = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(handle: handle),
      ),
    );
  }

  /// Parses a handle from a QR value string.
  /// Supports:
  ///   - `homeworkhelper://profile/@handle`
  ///   - `homeworkhelper://profile/handle`
  ///   - `homeworkhelper://u/handle`
  ///   - bare `@handle` or `handle`
  static String? _parseHandle(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Try URI parsing first.
    try {
      final uri = Uri.parse(trimmed);
      if (uri.scheme == 'homeworkhelper') {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          final last = segments.last.replaceFirst(RegExp(r'^@'), '');
          if (last.isNotEmpty) return last;
        }
      }
    } catch (_) {}

    // Bare @handle or handle.
    final bare = trimmed.replaceFirst(RegExp(r'^@'), '');
    if (RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(bare)) {
      return bare;
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
