import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_email_workflow.dart';

class AuthActionCodeScreen extends StatefulWidget {
  const AuthActionCodeScreen({
    super.key,
    required this.initialUri,
    this.onCompleted,
  });

  final Uri initialUri;
  final VoidCallback? onCompleted;

  @override
  State<AuthActionCodeScreen> createState() => _AuthActionCodeScreenState();
}

class _AuthActionCodeScreenState extends State<AuthActionCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  AuthActionLink? _link;
  String? _accountEmail;
  String? _errorMessage;
  bool _loading = true;
  bool _submitting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _link = AuthEmailWorkflow.tryParse(widget.initialUri);
    _bootstrap();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final link = _link;
    if (link == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'This link is not a valid auth action link.';
      });
      return;
    }

    if (link.isVerification) {
      await _verifyEmail(link);
      return;
    }

    if (link.isPasswordReset) {
      await _loadResetEmail(link);
      return;
    }

    setState(() {
      _loading = false;
      _errorMessage = 'This auth action is not supported in the app yet.';
    });
  }

  Future<void> _verifyEmail(AuthActionLink link) async {
    final code = link.oobCode;
    if (code == null || code.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Missing verification code.';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.applyActionCode(code);
      await context.read<AuthProvider>().refreshCurrentUser();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _completed = true;
      });
      widget.onCompleted?.call();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _friendlyAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not verify the email link.';
      });
    }
  }

  Future<void> _loadResetEmail(AuthActionLink link) async {
    final code = link.oobCode;
    if (code == null || code.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Missing password reset code.';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(code);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _accountEmail = email;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _friendlyAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load the password reset form.';
      });
    }
  }

  Future<void> _submitNewPassword() async {
    final link = _link;
    final code = link?.oobCode;
    if (link == null || code == null || code.isEmpty) {
      setState(() => _errorMessage = 'Missing password reset code.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _completed = true;
      });
      widget.onCompleted?.call();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = _friendlyAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Could not reset the password.';
      });
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'expired-action-code':
        return 'This link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This link is invalid or already used.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mode = _link?.type ?? AuthActionType.unknown;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(20),
              colorScheme.surface,
              colorScheme.secondary.withAlpha(14),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withAlpha(240),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _loading
                          ? _buildLoading(context, mode)
                          : _completed
                              ? _buildSuccess(context, mode)
                              : _errorMessage != null
                                  ? _buildError(context, mode)
                                  : _buildForm(context, mode),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, AuthActionType mode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          AuthEmailWorkflow.describeMode(mode),
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Verifying your request...',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, AuthActionType mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = mode == AuthActionType.verifyEmail
        ? 'Email verified'
        : 'Password reset complete';
    final body = mode == AuthActionType.verifyEmail
        ? 'Your account email has been verified. You can return to the app.'
        : 'Your password has been updated. You can sign in with the new password.';

    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, size: 72, color: colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (_accountEmail != null) ...[
          const SizedBox(height: 12),
          Text(
            _accountEmail!,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(BuildContext context, AuthActionType mode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 68, color: colorScheme.error),
        const SizedBox(height: 20),
        Text(
          AuthEmailWorkflow.describeMode(mode),
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => widget.onCompleted?.call(),
          child: const Text('Back to app'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthActionType mode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset_rounded, size: 68, color: colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            AuthEmailWorkflow.describeMode(mode),
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set a new password for ${_accountEmail ?? 'your account'}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.length < 6) {
                return 'Use at least 6 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text != _passwordController.text.trim()) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submitNewPassword,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update password'),
            ),
          ),
        ],
      ),
    );
  }
}
