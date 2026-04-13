import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSecrets {
  /// The Gemini API key.
  ///
  /// For web builds it is baked in at compile time via
  ///   `--dart-define=GEMINI_API_KEY=<value>`
  /// For local development and Android CI it falls back to the `.env` file
  /// (copy `.env.example` to `.env` and fill in your key).
  /// Returns an empty string when the key is not configured; API calls will
  /// fail gracefully with an error message shown in the chat interface.
  static const String _buildTimeKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get geminiApiKey =>
      _buildTimeKey.isNotEmpty ? _buildTimeKey : (dotenv.env['GEMINI_API_KEY'] ?? '');
}
