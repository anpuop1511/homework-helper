class AppSecrets {
  /// The Gemini API key, baked in at compile time via
  ///   `--dart-define=GEMINI_API_KEY=<value>`
  /// Returns an empty string when the key is not configured; API calls will
  /// fail gracefully with an error message shown in the chat interface.
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
