import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/user_provider.dart';
import 'main_scaffold.dart';

// Squircle / Expressive radius constants — 24.0 throughout.
const double _kCardRadius = 24.0;
const double _kInputRadius = 24.0;
const double _kButtonRadius = 24.0;
const double _kToggleContainerRadius = 24.0;
const double _kToggleTabRadius = 20.0;

/// A modern Material 3 Expressive login screen with Sign In / Sign Up modes.
///
/// Features:
/// - Dynamic / Material You color support via inherited [ColorScheme].
/// - Soft blob background painted by [_BlobBackgroundPainter].
/// - Bold Lexend headers, 24.0 border radius on inputs and buttons.
/// - [animate_do] FadeInDown / FadeInUp entrance animations.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignIn = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reverse().then((_) {
      setState(() => _isSignIn = !_isSignIn);
      _animController.forward();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<app_auth.AuthProvider>();
      if (_isSignIn) {
        await auth.signIn(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await auth.signUp(
          _emailController.text,
          _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }
      if (!mounted) return;
      final name = _nameController.text.trim();
      if (!_isSignIn && name.isNotEmpty) {
        context.read<UserProvider>().setName(name);
      }
      context.read<UserProvider>().recordActivity();
      // _AuthGate in main.dart now handles routing to UsernameScreen for any
      // signed-in user without a handle (new sign-up or existing account).
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(app_auth.AuthProvider.friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter your email above first.');
      return;
    }
    try {
      await context
          .read<app_auth.AuthProvider>()
          .sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(app_auth.AuthProvider.friendlyError(e));
    } catch (_) {
      if (!mounted) return;
      _showError('Could not send reset email. Please try again.');
    }
  }

  void _navigateAsGuest() {
    context.read<UserProvider>().recordActivity();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // ── Blob background ──────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _BlobBackgroundPainter(colorScheme: colorScheme),
            ),
          ),
          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App logo / branding
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withAlpha(60),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 44,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 150),
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Text(
                        'Homework Helper',
                        style: GoogleFonts.lexend(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Text(
                        'Stay organised. Stay ahead.',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Sign In / Sign Up toggle
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(_kToggleContainerRadius),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _ModeTab(
                            label: 'Sign In',
                            isSelected: _isSignIn,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (!_isSignIn) _toggleMode();
                            },
                          ),
                          _ModeTab(
                            label: 'Sign Up',
                            isSelected: !_isSignIn,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (_isSignIn) _toggleMode();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form card
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kCardRadius),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isSignIn) ...[
                                  Text(
                                    'Full Name',
                                    style: GoogleFonts.lexend(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Alex Johnson',
                                      prefixIcon:
                                          const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(_kInputRadius),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please enter your name'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  'Email',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(_kInputRadius),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Password',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(_kInputRadius),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Password must be at least 6 characters'
                                      : null,
                                ),
                                if (_isSignIn) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      child: Text(
                                        'Forgot password?',
                                        style: GoogleFonts.lexend(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(_kButtonRadius),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isSignIn
                                                ? 'Sign In'
                                                : 'Create Account',
                                            style: GoogleFonts.lexend(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: colorScheme.outlineVariant)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: colorScheme.outlineVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Continue as guest
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _navigateAsGuest,
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          'Continue as Guest',
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_kButtonRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blob background ──────────────────────────────────────────────────────────

/// Paints soft translucent blobs behind the login form for the
/// "Material You" mesh-gradient feel. Colors are derived from the
/// device's dynamic [ColorScheme].
class _BlobBackgroundPainter extends CustomPainter {
  final ColorScheme colorScheme;

  const _BlobBackgroundPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-right blob — primary
    paint.color = colorScheme.primaryContainer.withAlpha(90);
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * -0.05),
      size.width * 0.65,
      paint,
    );

    // Bottom-left blob — tertiary / secondary
    paint.color = colorScheme.secondaryContainer.withAlpha(70);
    canvas.drawCircle(
      Offset(size.width * -0.15, size.height * 1.05),
      size.width * 0.6,
      paint,
    );

    // Centre accent blob — very subtle
    paint.color = colorScheme.tertiaryContainer.withAlpha(40);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.45,
      paint,
    );

    // Small decorative blob — top-left
    paint.color = colorScheme.primary.withAlpha(20);
    final path = Path();
    final cx = size.width * 0.08;
    final cy = size.height * 0.22;
    final r = size.width * 0.22;
    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final wobble = r + math.sin(angle * 3) * r * 0.15;
      final x = cx + wobble * math.cos(angle);
      final y = cy + wobble * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BlobBackgroundPainter oldDelegate) =>
      oldDelegate.colorScheme != colorScheme;
}

// ── Mode tab ─────────────────────────────────────────────────────────────────

/// A tab button used inside the Sign In / Sign Up toggle strip.
class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(_kToggleTabRadius),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

