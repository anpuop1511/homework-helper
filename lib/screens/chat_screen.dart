import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

/// AI Study Buddy chat screen backed by the real Gemini API.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickPrompts = [
    'Explain photosynthesis',
    'Help with algebra',
    'Essay writing tips',
    'Study schedule advice',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inputController.clear();
    await context.read<ChatProvider>().sendMessage(trimmed);
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
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount:
                  chat.messages.length + (chat.isStreaming ? 0 : 0),
              itemBuilder: (context, index) {
                final msg = chat.messages[index];
                // Show streaming indicator on the last AI message if empty
                if (!msg.isUser &&
                    index == chat.messages.length - 1 &&
                    msg.text.isEmpty &&
                    chat.isStreaming) {
                  return RepaintBoundary(
                    child: _TypingIndicator(colorScheme: colorScheme),
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
          ),
        ],
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

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.isLoading,
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
                enabled: !isLoading,
                decoration: InputDecoration(
                  hintText: isLoading
                      ? 'Gemini is thinking…'
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
                onSubmitted: isLoading ? null : onSend,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: isLoading ? null : () => onSend(controller.text),
              elevation: 0,
              backgroundColor:
                  isLoading ? colorScheme.surfaceContainerHighest : colorScheme.primary,
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

