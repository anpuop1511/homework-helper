import 'dart:async';
import 'dart:typed_data';
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
  late ChatSession _session;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hi! I\'m your AI Study Buddy 🤖📚 powered by Gemini. '
          'Ask me anything about your homework and I\'ll help you understand it!',
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  bool _isStreaming = false;
  bool _isLiveActive = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  bool get isLiveActive => _isLiveActive;
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

  /// Sends an image (with an optional text prompt) to Gemini Vision and
  /// streams the reply back into [messages].
  Future<void> sendImageMessage(
    Uint8List imageBytes, {
    String prompt = 'Please explain this homework problem step by step.',
  }) async {
    if (_isStreaming) return;
    _error = null;

    // Add a user message indicating an image was sent.
    _messages.add(ChatMessage(
      text: '📷 ${prompt.isEmpty ? "What can you see in this image?" : prompt}',
      isUser: true,
      time: DateTime.now(),
    ));
    _isStreaming = true;
    notifyListeners();

    // Add placeholder for the AI response.
    _messages.add(ChatMessage(
      text: '',
      isUser: false,
      time: DateTime.now(),
    ));
    final aiIndex = _messages.length - 1;

    try {
      // Vision model — use gemini-1.5-flash which supports multimodal input.
      final visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppSecrets.geminiApiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      final response = await visionModel.generateContent([
        Content.multi([
          TextPart(prompt.isNotEmpty
              ? prompt
              : 'Please explain this homework problem step by step.'),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text ?? '⚠️ No response from Gemini Vision.';
      _messages[aiIndex] = _messages[aiIndex].copyWith(text: text);
    } on GenerativeAIException catch (e) {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: '⚠️ Sorry, I couldn\'t analyse the image. '
            'Please check your internet connection.\n\n(${e.message})',
      );
      _error = e.message;
      debugPrint('[ChatProvider] Gemini Vision error: ${e.message}');
    } catch (e) {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: '⚠️ An unexpected error occurred while analysing the image.',
      );
      _error = e.toString();
      debugPrint('[ChatProvider] Unexpected Vision error: $e');
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// Toggles Gemini Live Voice mode on/off.
  ///
  /// This is a placeholder for the Gemini Live API integration.
  /// When [isLiveActive] is true, the UI shows the waveform pulse overlay.
  void startLiveVoice() {
    _isLiveActive = !_isLiveActive;
    notifyListeners();
  }

  /// Sends an image to Gemini Vision and returns the extracted task title.
  ///
  /// Unlike [sendImageMessage], this method does **not** add anything to the
  /// chat history — it's designed for silent extraction in the AddTaskSheet.
  Future<String?> extractTaskFromImage(Uint8List imageBytes) async {
    try {
      final visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppSecrets.geminiApiKey,
      );
      final response = await visionModel.generateContent([
        Content.multi([
          TextPart(
            'Extract the main assignment or homework task title from this '
            'worksheet image. Return only a short task title (max 10 words), '
            'nothing else.',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);
      return response.text?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Clears the conversation and starts a fresh chat session.
  void clearChat() {
    _session = _model.startChat();
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
