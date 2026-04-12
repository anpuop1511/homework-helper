import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Available AI model identifiers.
///
/// - [gemini25Flash] – default, Gemini 2.5 Flash (fast & capable).
/// - [gemini30Flash] – Gemini 3.0 Flash (cutting-edge, limited quota).
/// - [custom] – Bring Your Own Key (BYOK); uses [ChatProvider.customApiKey].
enum AiModel {
  gemini25Flash,
  gemini30Flash,
  custom;

  /// The model string sent to the Generative AI SDK.
  String get modelId {
    switch (this) {
      case AiModel.gemini25Flash:
        return 'gemini-2.5-flash';
      case AiModel.gemini30Flash:
        return 'gemini-3.0-flash';
      case AiModel.custom:
        return 'gemini-2.5-flash';
    }
  }

  /// Human-readable display label shown in the Settings UI.
  String get label {
    switch (this) {
      case AiModel.gemini25Flash:
        return 'Gemini 2.5 Flash';
      case AiModel.gemini30Flash:
        return 'Gemini 3.0 Flash (Limited)';
      case AiModel.custom:
        return 'Custom / BYOK';
    }
  }
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

  static const _kHistoryEnabled = 'chat_history_enabled';
  static const _kSelectedModel = 'chat_selected_model';
  static const _kCustomApiKey = 'chat_custom_api_key';

  GenerativeModel? _model;
  ChatSession? _session;

  /// The currently selected AI model.
  AiModel _selectedModel = AiModel.gemini25Flash;

  /// Custom API key provided by the user for BYOK mode.
  String _customApiKey = '';

  static ChatMessage _welcomeMessage() => ChatMessage(
        text: 'Hi! I\'m your AI Study Buddy 🤖📚 powered by Gemini. '
            'Ask me anything about your homework and I\'ll help you understand it!',
        isUser: false,
        time: DateTime.now(),
      );

  final List<ChatMessage> _messages = [_welcomeMessage()];

  /// Ephemeral messages used when Ghost Mode is active.
  /// Cleared when Ghost Mode is disabled or [clearChat] is called.
  final List<ChatMessage> _ghostMessages = [_welcomeMessage()];

  bool _isStreaming = false;
  bool _isLiveActive = false;
  bool _isHistoryEnabled = true;
  String? _error;

  /// The list of messages the chat UI should display.
  ///
  /// Returns the persistent list when history is enabled (normal mode),
  /// or the ephemeral ghost list when Ghost Mode is active.
  List<ChatMessage> get messages =>
      _isHistoryEnabled
          ? List.unmodifiable(_messages)
          : List.unmodifiable(_ghostMessages);

  bool get isStreaming => _isStreaming;
  bool get isLiveActive => _isLiveActive;

  /// When `false` (Ghost Mode) new messages are sent to an ephemeral buffer
  /// and are not retained in the persistent history.
  bool get isHistoryEnabled => _isHistoryEnabled;

  String? get error => _error;

  /// The currently selected AI model.
  AiModel get selectedModel => _selectedModel;

  /// The user-provided API key for BYOK mode (may be empty).
  String get customApiKey => _customApiKey;

  /// Returns the effective API key: custom key if BYOK selected and non-empty,
  /// otherwise the default app key.
  String get _effectiveApiKey {
    if (_selectedModel == AiModel.custom && _customApiKey.isNotEmpty) {
      return _customApiKey;
    }
    return AppSecrets.geminiApiKey;
  }

  ChatProvider() {
    _loadPrefs();
  }

  /// Lazily creates [_model] and [_session] on first use so the constructor
  /// does not access [AppSecrets.geminiApiKey] before [dotenv] is ready.
  void _ensureModel() {
    if (_model != null) return;
    _model = GenerativeModel(
      model: _selectedModel.modelId,
      apiKey: _effectiveApiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _session ??= _model!.startChat();
  }

  /// Rebuilds the model when settings change (model or API key).
  void _rebuildModel() {
    _model = GenerativeModel(
      model: _selectedModel.modelId,
      apiKey: _effectiveApiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _session = _model!.startChat();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isHistoryEnabled = prefs.getBool(_kHistoryEnabled) ?? true;
    final modelIndex = prefs.getInt(_kSelectedModel);
    if (modelIndex != null && modelIndex < AiModel.values.length) {
      _selectedModel = AiModel.values[modelIndex];
    }
    _customApiKey = prefs.getString(_kCustomApiKey) ?? '';
    notifyListeners();
  }

  /// Changes the active AI model and persists the choice.
  Future<void> setModel(AiModel model) async {
    if (_selectedModel == model) return;
    _selectedModel = model;
    _rebuildModel();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSelectedModel, model.index);
  }

  /// Updates the custom BYOK API key and persists it.
  Future<void> setCustomApiKey(String key) async {
    final trimmed = key.trim();
    if (_customApiKey == trimmed) return;
    _customApiKey = trimmed;
    if (_selectedModel == AiModel.custom) {
      _rebuildModel();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCustomApiKey, trimmed);
  }

  /// Enables or disables Ghost Mode (chat history recording).
  ///
  /// When disabled the ghost-message buffer is cleared so the chat starts
  /// fresh in ephemeral mode.
  Future<void> setHistoryEnabled(bool value) async {
    if (_isHistoryEnabled == value) return;
    _isHistoryEnabled = value;
    if (!value) {
      // Entering ghost mode — reset the ghost buffer to a fresh welcome.
      _ghostMessages
        ..clear()
        ..add(_welcomeMessage());
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHistoryEnabled, value);
  }

  /// Deletes a message at [index] from the persistent history.
  ///
  /// The welcome message (index 0) cannot be removed.
  void deleteMessage(int index) {
    if (index <= 0 || index >= _messages.length) return;
    _messages.removeAt(index);
    notifyListeners();
  }

  /// Sends [userText] to Gemini and streams the reply back into the active
  /// message list.  When Ghost Mode is active the exchange is written to the
  /// ephemeral buffer and will not appear in the persistent history.
  Future<void> sendMessage(String userText) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty || _isStreaming) return;
    _ensureModel();

    _error = null;

    // Write to the active list (persistent or ghost).
    final list = _isHistoryEnabled ? _messages : _ghostMessages;

    // Add user message immediately
    list.add(ChatMessage(
      text: trimmed,
      isUser: true,
      time: DateTime.now(),
    ));
    _isStreaming = true;
    notifyListeners();

    // Add placeholder for the AI response
    list.add(ChatMessage(
      text: '',
      isUser: false,
      time: DateTime.now(),
    ));
    final aiIndex = list.length - 1;

    try {
      final stream = _session!.sendMessageStream(
        Content.text(trimmed),
      );

      await for (final chunk in stream) {
        final chunkText = chunk.text ?? '';
        final current = list[aiIndex];
        list[aiIndex] = current.copyWith(text: current.text + chunkText);
        notifyListeners();
      }
    } on GenerativeAIException catch (e) {
      list[aiIndex] = list[aiIndex].copyWith(
        text: '⚠️ Sorry, I couldn\'t connect to Gemini. '
            'Please check your internet connection.\n\n(${e.message})',
      );
      _error = e.message;
      debugPrint('[ChatProvider] Gemini error: ${e.message}');
    } catch (e) {
      list[aiIndex] = list[aiIndex].copyWith(
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
  /// streams the reply back into the active message list.
  Future<void> sendImageMessage(
    Uint8List imageBytes, {
    String prompt = 'Please explain this homework problem step by step.',
  }) async {
    if (_isStreaming) return;
    _error = null;

    final list = _isHistoryEnabled ? _messages : _ghostMessages;

    // Add a user message indicating an image was sent.
    list.add(ChatMessage(
      text: '📷 ${prompt.isEmpty ? "What can you see in this image?" : prompt}',
      isUser: true,
      time: DateTime.now(),
    ));
    _isStreaming = true;
    notifyListeners();

    // Add placeholder for the AI response.
    list.add(ChatMessage(
      text: '',
      isUser: false,
      time: DateTime.now(),
    ));
    final aiIndex = list.length - 1;

    try {
      // Vision model — use the selected model for multimodal input.
      final visionModel = GenerativeModel(
        model: _selectedModel.modelId,
        apiKey: _effectiveApiKey,
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
      list[aiIndex] = list[aiIndex].copyWith(text: text);
    } on GenerativeAIException catch (e) {
      list[aiIndex] = list[aiIndex].copyWith(
        text: '⚠️ Sorry, I couldn\'t analyse the image. '
            'Please check your internet connection.\n\n(${e.message})',
      );
      _error = e.message;
      debugPrint('[ChatProvider] Gemini Vision error: ${e.message}');
    } catch (e) {
      list[aiIndex] = list[aiIndex].copyWith(
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
        model: _selectedModel.modelId,
        apiKey: _effectiveApiKey,
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
  ///
  /// Resets both the persistent history and the ghost-mode buffer.
  void clearChat() {
    _ensureModel();
    _session = _model!.startChat();
    _messages
      ..clear()
      ..add(_welcomeMessage());
    _ghostMessages
      ..clear()
      ..add(_welcomeMessage());
    _error = null;
    _isStreaming = false;
    notifyListeners();
  }
}
