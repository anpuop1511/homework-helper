import 'dart:convert';

import 'package:http/http.dart' as http;

class NewsletterService {
  NewsletterService._();

  static const String _backendBaseUrl = String.fromEnvironment(
    'NEWSLETTER_API_BASE_URL',
    defaultValue: 'https://www.hwhelper.tech/api',
  );

  static Uri get _newsletterUri => Uri.parse('$_backendBaseUrl/newsletter');

  static Future<void> subscribe(String email) {
    return _postAction(action: 'subscribe', email: email);
  }

  static Future<void> unsubscribe(String email) {
    return _postAction(action: 'unsubscribe', email: email);
  }

  static Future<Map<String, dynamic>> sendCampaign({
    required String adminToken,
    required String subject,
    required String html,
    String? text,
    List<String>? recipients,
  }) async {
    final decoded = await _postAction(
      action: 'send',
      email: null,
      headers: {'x-newsletter-admin-token': adminToken.trim()},
      extraFields: {
        'subject': subject.trim(),
        'html': html,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        if (recipients != null && recipients.isNotEmpty)
          'recipients': recipients.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      },
    );

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  static Future<dynamic> _postAction({
    required String action,
    required String? email,
    Map<String, String>? headers,
    Map<String, dynamic>? extraFields,
  }) async {
    final payload = <String, dynamic>{
      'action': action,
      if (email != null) 'email': email.trim(),
      ...?extraFields,
    };

    final response = await http.post(
      _newsletterUri,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(payload),
    );

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final responseText = response.body;
    String message = 'Newsletter request failed.';
    if (decoded is Map && decoded['message'] is String) {
      message = decoded['message'] as String;
    } else if (responseText.isNotEmpty) {
      message = responseText;
    }

    throw StateError(message);
  }
}
