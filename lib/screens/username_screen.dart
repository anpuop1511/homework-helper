import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

/// Shown once after account creation so the user can pick their unique @handle.
class UsernameScreen extends StatefulWidget {
  /// Whether the screen was launched from [ProfileScreen] for an existing user
  /// who has not yet chosen a handle.  When true the back button is shown.
  final bool allowSkip;

  const UsernameScreen({super.key, this.allowSkip = false});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _serverError;

  // Regex: 3–20 chars, letters, digits, underscores only (no leading digit/underscore).
  static final _handlePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{2,19}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _serverError = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final handle = _controller.text.trim().toLowerCase();
    setState(() => _saving = true);

    final uid = context.read<AuthProvider>().uid;
    if (uid == null) {
      setState(() => _saving = false);
      return;
    }

    final error =
        await DatabaseService.instance.claimUsername(uid, handle);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _serverError = error;
      });
      _formKey.currentState?.validate();
      return;
    }

    // Refresh the in-memory username so the rest of the app reflects it.
    await context.read<AuthProvider>().refreshUsername();
    if (!mounted) return;

    if (widget.allowSkip) {
      Navigator.of(context).pop();
    }
    // When launched from _AuthGate (allowSkip == false), the gate will rebuild
    // automatically now that AuthProvider.username is set – no manual push needed.
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: widget.allowSkip
          ? AppBar(
              backgroundColor: colorScheme.surface,
              elevation: 0,
              title: Text(
                'Pick your @handle',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.allowSkip) const SizedBox(height: 32),
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.alternate_email_rounded,
                      size: 44,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInDown(
                delay: const Duration(milliseconds: 80),
                duration: const Duration(milliseconds: 400),
                child: Center(
                  child: Text(
                    'Choose your @handle',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 120),
                duration: const Duration(milliseconds: 400),
                child: Center(
                  child: Text(
                    'Your unique handle lets friends find you\nwithout sharing your private email.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              FadeInUp(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 400),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      prefixText: '@',
                      prefixStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      hintText: 'e.g. study_legend',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) {
                      if (_serverError != null) return _serverError;
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a username.';
                      }
                      if (!_handlePattern.hasMatch(v.trim())) {
                        return 'Must start with a letter, 3–20 chars, letters/digits/_ only.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '3–20 characters · letters, numbers and _ only',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Claim my @handle',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              if (widget.allowSkip) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Skip for now',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
