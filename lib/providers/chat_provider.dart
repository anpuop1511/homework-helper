import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/secrets.dart';

/// Represents a single message in the study chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  ChatMessage copyWith({String? text}) => ChatMessage(
        text: text ?? this.text,
        isUser: isUser,
        time: time,
      );
}

/// Manages the AI Study Buddy chat state and Gemini API integration.
///
/// Exposes a [messages] list and a [isStreaming] flag that the UI can
/// watch via `context.watch<ChatProvider>()`.
class ChatProvider extends ChangeNotifier {
  static const String _systemPrompt =
      'You are an AI Study Buddy for a homework helper app. '
      'Your role is to help students understand their homework, '
      'explain concepts clearly, provide step-by-step solutions, '
      'and give study tips. Be encouraging, concise, and use '
      'appropriate emojis to make learning fun. Format math '
      'with plain text (not LaTeX). Keep responses focused.';

  late final GenerativeModel _model;
  late final ChatSession _session;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hi! I\'m your AI Study Buddy 🤖📚 powered by Gemini. '
          'Ask me anything about your homework and I\'ll help you understand it!',
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  bool _isStreaming = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  ChatProvider() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppSecrets.geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _session = _model.startChat();
  }

  /// Sends [userText] to Gemini and streams the reply back into [messages].
  Future<void> sendMessage(String userText) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty || _isStreaming) return;

    _error = null;

    // Add user message immediately
    _messages.add(ChatMessage(
      text: trimmed,
      isUser: true,
      time: DateTime.now(),
    ));
    _isStreaming = true;
    notifyListeners();

    // Add placeholder for the AI response
    _messages.add(ChatMessage(
      text: '',
      isUser: false,
      time: DateTime.now(),
    ));
    final aiIndex = _messages.length - 1;

    try {
      final stream = _session.sendMessageStream(
        Content.text(trimmed),
      );

      await for (final chunk in stream) {
        final chunkText = chunk.text ?? '';
        final current = _messages[aiIndex];
        _messages[aiIndex] = current.copyWith(text: current.text + chunkText);
        notifyListeners();
      }
    } on GenerativeAIException catch (e) {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: '⚠️ Sorry, I couldn\'t connect to Gemini. '
            'Please check your internet connection.\n\n(${e.message})',
      );
      _error = e.message;
      debugPrint('[ChatProvider] Gemini error: ${e.message}');
    } catch (e) {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: '⚠️ An unexpected error occurred. Please try again.',
      );
      _error = e.toString();
      debugPrint('[ChatProvider] Unexpected error: $e');
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// Clears the conversation and starts a fresh chat session.
  void clearChat() {
    _session.history.clear();
    _messages
      ..clear()
      ..add(ChatMessage(
        text: 'Hi! I\'m your AI Study Buddy 🤖📚 powered by Gemini. '
            'Ask me anything about your homework and I\'ll help you understand it!',
        isUser: false,
        time: DateTime.now(),
      ));
    _error = null;
    _isStreaming = false;
    notifyListeners();
  }
}
