import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A Material You "Squircle" avatar widget.
///
/// Shows a [photoUrl] network image when provided, or a local [localPhotoBytes]
/// preview, otherwise renders the user's initial letter in a colourful,
/// smoothly-rounded card.
class SquircleAvatar extends StatelessWidget {
  final double radius;
  final String initial;
  final String? photoUrl;
  final Uint8List? localPhotoBytes;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? frameCosmeticId;

  const SquircleAvatar({
    super.key,
    required this.radius,
    required this.initial,
    this.photoUrl,
    this.localPhotoBytes,
    this.backgroundColor,
    this.foregroundColor,
    this.frameCosmeticId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = radius * 2;
    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    ImageProvider? imageProvider;
    if (localPhotoBytes != null) {
      imageProvider = MemoryImage(localPhotoBytes!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    final avatarCore = ClipRRect(
      borderRadius: BorderRadius.circular(radius * 0.55),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg),
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialWidget(
                  initial: initial,
                  fg: fg,
                  radius: radius,
                ),
              )
            : _InitialWidget(
                initial: initial,
                fg: fg,
                radius: radius,
              ),
      ),
    );

    if (frameCosmeticId != 'sharpener_profile_frame') {
      return avatarCore;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular((radius + 5) * 0.55),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEB3B), Color(0xFF212121)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAAFFEB3B),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        avatarCore,
      ],
    );
  }
}

class _InitialWidget extends StatelessWidget {
  final String initial;
  final Color fg;
  final double radius;

  const _InitialWidget({
    required this.initial,
    required this.fg,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial.isNotEmpty ? initial[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
