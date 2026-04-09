import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A chat message data class.
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

/// AI Study Buddy chat screen with expressive message bubbles.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hi! I\'m your AI Study Buddy 🤖📚. Ask me anything about your homework, '
          'and I\'ll do my best to help you understand it!',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  static const List<String> _quickPrompts = [
    'Explain photosynthesis',
    'Help with algebra',
    'Essay writing tips',
    'Study schedule advice',
  ];

  // Mock AI response map – returns a relevant reply based on keywords.
  String _generateReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('photosynthesis') || lower.contains('science')) {
      return 'Photosynthesis is the process plants use to convert light energy into '
          'chemical energy (glucose) 🌿. The equation is:\n\n'
          '6CO₂ + 6H₂O + light → C₆H₁₂O₆ + 6O₂\n\n'
          'The two stages are the light-dependent reactions (in the thylakoid) and '
          'the Calvin cycle (in the stroma). Would you like me to explain either stage in more detail?';
    } else if (lower.contains('algebra') || lower.contains('math') ||
        lower.contains('equation')) {
      return 'Great question! 🔢 When solving algebraic equations, remember PEMDAS '
          '(Parentheses, Exponents, Multiplication/Division, Addition/Subtraction).\n\n'
          'For linear equations like 2x + 5 = 11:\n'
          '1. Subtract 5 from both sides → 2x = 6\n'
          '2. Divide both sides by 2 → x = 3\n\n'
          'Always perform the same operation on both sides! Would you like to practice a problem together?';
    } else if (lower.contains('essay') || lower.contains('writing') ||
        lower.contains('english')) {
      return 'Writing a strong essay starts with a clear thesis statement 📝. '
          'Here\'s a simple structure to follow:\n\n'
          '1. **Introduction** – Hook, background, thesis\n'
          '2. **Body Paragraphs** – Topic sentence, evidence, analysis\n'
          '3. **Conclusion** – Restate thesis, summarise, final thought\n\n'
          'Aim for 5 paragraphs in a standard essay. Do you want help crafting a thesis for a specific topic?';
    } else if (lower.contains('study') || lower.contains('schedule') ||
        lower.contains('plan')) {
      return 'Great study habits make a huge difference! ⏰ Try the Pomodoro Technique:\n\n'
          '• Study for 25 minutes\n'
          '• Take a 5-minute break\n'
          '• Repeat 4 times\n'
          '• Take a longer 15-20 min break\n\n'
          'You can use the Focus Timer tab in this app to track your sessions! Also, '
          'reviewing material right before sleep can improve retention by up to 20%.';
    } else if (lower.contains('history') || lower.contains('war')) {
      return 'History is about understanding cause and effect! 🏛️ When studying historical events, '
          'try to identify:\n\n'
          '• **Who** were the key figures?\n'
          '• **What** happened (events and timeline)?\n'
          '• **Why** did it happen (causes)?\n'
          '• **What were the effects** (short-term and long-term)?\n\n'
          'Using mind maps can be a great way to visualise these connections. '
          'Which historical period are you studying?';
    } else {
      return 'That\'s a great question! 🌟 To give you the best help, could you provide '
          'a bit more detail? For example:\n\n'
          '• What subject is this for?\n'
          '• What have you already tried or understood so far?\n'
          '• Is there a specific part that\'s confusing you?\n\n'
          'The more context you share, the better I can tailor my explanation!';
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate AI thinking delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        text: _generateReply(trimmed),
        isUser: false,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
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
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Study Buddy',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Always ready to help',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Quick-prompt chips
          if (_messages.length <= 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _TypingIndicator(colorScheme: colorScheme);
                }
                final msg = _messages[index];
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
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// An individual chat message bubble, styled differently for user vs AI.
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Study Buddy',
                      style: GoogleFonts.outfit(
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
                style: GoogleFonts.outfit(
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

/// Animated typing indicator shown while the AI is generating a response.
class _TypingIndicator extends StatefulWidget {
  final ColorScheme colorScheme;

  const _TypingIndicator({required this.colorScheme});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _controllers
        .map((c) => Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _anims[i],
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8 + _anims[i].value * 4,
                decoration: BoxDecoration(
                  color: widget.colorScheme.onSecondaryContainer
                      .withAlpha(
                          (153 + (_anims[i].value * 102)).clamp(0, 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// The text input bar at the bottom of the chat screen.
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final ColorScheme colorScheme;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
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
                decoration: InputDecoration(
                  hintText: 'Ask anything…',
                  hintStyle: GoogleFonts.outfit(
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
                onSubmitted: onSend,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: () => onSend(controller.text),
              elevation: 0,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.send_rounded, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
