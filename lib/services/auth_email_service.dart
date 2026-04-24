import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthEmailService {
  AuthEmailService._();

  static const String _backendBaseUrl = String.fromEnvironment(
    'AUTH_EMAIL_API_BASE_URL',
    defaultValue: 'https://homework-helper-web-dun.vercel.app/api',
  );

  static Uri get _sendAuthEmailUri =>
      Uri.parse('$_backendBaseUrl/send-auth-email');

  static Future<void> sendVerificationEmail({
    required String email,
    String? displayName,
  }) {
    return _sendAuthEmail(
      action: 'verifyEmail',
      email: email,
      displayName: displayName,
    );
  }

  static Future<void> sendPasswordResetEmail({required String email}) {
    return _sendAuthEmail(
      action: 'resetPassword',
      email: email,
    );
  }

  static Future<void> _sendAuthEmail({
    required String action,
    required String email,
    String? displayName,
  }) async {
    final response = await http.post(
      _sendAuthEmailUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'email': email.trim(),
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final responseText = response.body;
    String message = 'Could not send the email.';
    try {
      final decoded = jsonDecode(responseText);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      if (responseText.isNotEmpty) {
        message = responseText;
      }
    }

    throw StateError(message);
  }
}