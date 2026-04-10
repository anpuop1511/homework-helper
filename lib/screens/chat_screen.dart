import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/chat_provider.dart';

// Electric Blue — same as the NFC bump screen glow.
const Color _kElectricBlue = Color(0xFF007FFF);

/// AI Study Buddy chat screen backed by the real Gemini API.
/// V2.4: Voice-to-Voice mode with animated waveform UI.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// Voice interaction state machine.
enum _VoiceState {
  idle,      // normal text chat
  listening, // microphone active, user speaking
  speaking,  // TTS reading the AI response
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Voice ──────────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  _VoiceState _voiceState = _VoiceState.idle;
  String _partialWords = '';

  // ── Waveform animation ─────────────────────────────────────────────
  late final AnimationController _waveController;

  static const List<String> _quickPrompts = [
    'Explain photosynthesis',
    'Help with algebra',
    'Essay writing tips',
    'Study schedule advice',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _voiceState = _VoiceState.idle);
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _voiceState = _VoiceState.speaking);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _voiceState = _VoiceState.idle);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _voiceState = _VoiceState.idle);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _voiceState = _VoiceState.idle);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inputController.clear();
    final provider = context.read<ChatProvider>();
    await provider.sendMessage(trimmed);
    _scrollToBottom();
  }

  /// Send a voice-transcribed message and speak the AI response when done.
  Future<void> _sendVoiceMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _voiceState = _VoiceState.idle);
      return;
    }
    final provider = context.read<ChatProvider>();
    await provider.sendMessage(trimmed);
    _scrollToBottom();
    // Read aloud the AI's final response.
    final messages = provider.messages;
    if (messages.isNotEmpty && !messages.last.isUser) {
      final aiText = messages.last.text;
      if (aiText.isNotEmpty && mounted) {
        await _tts.speak(aiText);
        return; // TTS handlers will update _voiceState
      }
    }
    if (mounted) setState(() => _voiceState = _VoiceState.idle);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) return;
    await _tts.stop();
    setState(() {
      _voiceState = _VoiceState.listening;
      _partialWords = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _partialWords = result.recognizedWords);
        if (result.finalResult) {
          _speech.stop();
          final words = result.recognizedWords;
          setState(() {
            _voiceState = _VoiceState.idle;
            _partialWords = '';
          });
          _sendVoiceMessage(words);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    final words = _partialWords;
    await _speech.stop();
    setState(() {
      _voiceState = _VoiceState.idle;
      _partialWords = '';
    });
    if (words.isNotEmpty) {
      await _sendVoiceMessage(words);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chat = context.watch<ChatProvider>();

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _GlassAppBar(
        colorScheme: colorScheme,
        textTheme: textTheme,
        onClear: chat.messages.length > 1
            ? () => context.read<ChatProvider>().clearChat()
            : null,
      ),
      body: Column(
        children: [
          // Quick-prompt chips – only shown before the first user message
          if (chat.messages.length <= 1) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick questions',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _quickPrompts.map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        onPressed: () => _sendMessage(prompt),
                        avatar: const Icon(Icons.lightbulb_outline, size: 16),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
          ],
          // ── Voice overlay (listening / speaking) ────────────────────
          if (_voiceState != _VoiceState.idle)
            _VoiceOverlay(
              voiceState: _voiceState,
              partialWords: _partialWords,
              waveController: _waveController,
              colorScheme: colorScheme,
              textTheme: textTheme,
              onStop: _voiceState == _VoiceState.listening
                  ? _stopListening
                  : () async {
                      await _tts.stop();
                      setState(() => _voiceState = _VoiceState.idle);
                    },
            ),
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: chat.messages.length,
              itemBuilder: (context, index) {
                final msg = chat.messages[index];
                // While Gemini is streaming, the last AI message starts as an
                // empty placeholder – show the typing indicator until text arrives.
                if (!msg.isUser &&
                    index == chat.messages.length - 1 &&
                    msg.text.isEmpty &&
                    chat.isStreaming) {
                  return RepaintBoundary(
                    child: _voiceState != _VoiceState.idle
                        ? _InlineWaveform(
                            waveController: _waveController,
                            colorScheme: colorScheme,
                          )
                        : _TypingIndicator(colorScheme: colorScheme),
                  );
                }
                return _MessageBubble(
                  message: msg,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                );
              },
            ),
          ),
          // Input bar
          _ChatInputBar(
            controller: _inputController,
            onSend: _sendMessage,
            isLoading: chat.isStreaming,
            colorScheme: colorScheme,
            voiceState: _voiceState,
            speechEnabled: _speechEnabled,
            onMicTap: _voiceState == _VoiceState.listening
                ? _stopListening
                : _startListening,
          ),
        ],
      ),
    );
  }
}

// ── Voice Overlay ─────────────────────────────────────────────────────────────

/// Full-width banner shown at the top of the chat when in listening or
/// speaking state.  Features the animated Electric Blue waveform with glow.
class _VoiceOverlay extends StatelessWidget {
  final _VoiceState voiceState;
  final String partialWords;
  final AnimationController waveController;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onStop;

  const _VoiceOverlay({
    required this.voiceState,
    required this.partialWords,
    required this.waveController,
    required this.colorScheme,
    required this.textTheme,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = voiceState == _VoiceState.listening;
    final label = isListening ? 'Listening…' : 'Speaking…';
    final subLabel = isListening && partialWords.isNotEmpty
        ? '"$partialWords"'
        : isListening
            ? 'Tap the mic to stop'
            : 'Tap to stop';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Waveform with Electric Blue glow
          _WaveformBars(controller: waveController, barCount: 9),
          const SizedBox(width: 16),
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _kElectricBlue,
                  ),
                ),
                Text(
                  subLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Stop button
          IconButton(
            icon: Icon(
              isListening ? Icons.mic_off_rounded : Icons.stop_rounded,
              color: _kElectricBlue,
            ),
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

// ── Waveform Bars (Electric Blue, glow) ──────────────────────────────────────

/// Animated audio waveform bars with Electric Blue glow — matches the NFC
/// bump screen's visual identity.
class _WaveformBars extends StatelessWidget {
  final AnimationController controller;
  final int barCount;

  const _WaveformBars({required this.controller, this.barCount = 7});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return SizedBox(
          width: barCount * 10.0,
          height: 40,
          child: CustomPaint(
            painter: _WaveformPainter(
              progress: controller.value,
              barCount: barCount,
              color: _kElectricBlue,
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final int barCount;
  final Color color;

  const _WaveformPainter({
    required this.progress,
    required this.barCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (barCount * 2 - 1);
    final maxH = size.height * 0.9;
    final minH = size.height * 0.15;

    for (int i = 0; i < barCount; i++) {
      final phase = (progress + i * (1.0 / barCount)) % 1.0;
      final h = minH + (math.sin(phase * 2 * math.pi) * 0.5 + 0.5) * (maxH - minH);
      final x = i * barWidth * 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          (size.height - h) / 2,
          barWidth,
          h,
        ),
        const Radius.circular(4),
      );

      // Glow layer
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withAlpha(60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Solid layer
      canvas.drawRRect(
        rect,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Inline waveform (replaces typing dots in voice mode) ─────────────────────

class _InlineWaveform extends StatelessWidget {
  final AnimationController waveController;
  final ColorScheme colorScheme;

  const _InlineWaveform({
    required this.waveController,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: _WaveformBars(controller: waveController, barCount: 7),
      ),
    );
  }
}

// ── Glass AppBar ─────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onClear;

  const _GlassAppBar({
    required this.colorScheme,
    required this.textTheme,
    this.onClear,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: colorScheme.surface.withAlpha(200),
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gemini Study Buddy',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Powered by Gemini AI',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Clear chat',
                onPressed: onClear,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MessageBubble({
    required this.message,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isUser ? 48 : 0,
            right: isUser ? 0 : 48,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? colorScheme.primaryContainer
                : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Study Buddy',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message.text,
                style: textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.time.hour.toString().padLeft(2, '0')}:'
                '${message.time.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  color: isUser
                      ? colorScheme.onPrimaryContainer.withAlpha(153)
                      : colorScheme.onSecondaryContainer.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator (optimised CustomPainter) ────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final ColorScheme colorScheme;

  const _TypingIndicator({required this.colorScheme});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 48,
          height: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _DotsPainter(
                progress: _controller.value,
                color: widget.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Efficient single-controller dots painter – avoids 3 separate controllers.
class _DotsPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _DotsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const dotCount = 3;
    final dotSpacing = size.width / dotCount;
    const baseRadius = 4.0;
    const bounceHeight = 4.0;

    for (int i = 0; i < dotCount; i++) {
      final phase = (progress - i * 0.25) % 1.0;
      final bounce = phase < 0.5
          ? phase * 2
          : 1.0 - (phase - 0.5) * 2;
      final radius = baseRadius + bounce * 1.5;
      final alpha = (153 + bounce * 102).clamp(0, 255).toInt();
      paint.color = color.withAlpha(alpha);
      final cx = dotSpacing * i + dotSpacing / 2;
      final cy = size.height / 2 - bounce * bounceHeight;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Input Bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool isLoading;
  final ColorScheme colorScheme;
  final _VoiceState voiceState;
  final bool speechEnabled;
  final VoidCallback onMicTap;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.colorScheme,
    required this.voiceState,
    required this.speechEnabled,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = voiceState == _VoiceState.listening;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                enabled: !isLoading && voiceState == _VoiceState.idle,
                decoration: InputDecoration(
                  hintText: isLoading
                      ? 'Gemini is thinking…'
                      : isListening
                          ? 'Listening…'
                          : 'Ask anything…',
                  hintStyle: GoogleFonts.lexend(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                onSubmitted:
                    isLoading || voiceState != _VoiceState.idle ? null : onSend,
              ),
            ),
            const SizedBox(width: 8),
            // Microphone button (shown when speech is supported)
            if (speechEnabled) ...[
              FloatingActionButton.small(
                heroTag: 'mic_fab',
                onPressed:
                    isLoading || voiceState == _VoiceState.speaking
                        ? null
                        : onMicTap,
                elevation: 0,
                backgroundColor: isListening
                    ? _kElectricBlue
                    : colorScheme.surfaceContainerHighest,
                child: Icon(
                  isListening
                      ? Icons.mic_rounded
                      : Icons.mic_none_rounded,
                  color: isListening
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Send button
            FloatingActionButton.small(
              heroTag: 'send_fab',
              onPressed: isLoading || voiceState != _VoiceState.idle
                  ? null
                  : () => onSend(controller.text),
              elevation: 0,
              backgroundColor: isLoading || voiceState != _VoiceState.idle
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primary,
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}


