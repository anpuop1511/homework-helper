import 'package:flutter/material.dart';

/// A widget that renders [text] filled with a [gradient].
///
/// Uses [ShaderMask] with [BlendMode.srcIn] so the gradient is clipped to
/// the text glyphs — the background remains transparent.
///
/// Works in both light and dark themes and is suitable for decorative
/// headings such as AI-style greeting text.
///
/// Example:
/// ```dart
/// GradientText(
///   'Good morning, Alex',
///   style: Theme.of(context).textTheme.headlineMedium,
///   gradient: const LinearGradient(
///     colors: [Color(0xFF7B61FF), Color(0xFF00CFFF)],
///   ),
/// )
/// ```
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}
