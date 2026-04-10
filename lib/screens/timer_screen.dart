import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Pomodoro-style focus timer with circular progress and expressive animations.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  static const int _workMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;

  _TimerMode _mode = _TimerMode.work;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  int _completedSessions = 0;
  Timer? _timer;

  late final AnimationController _successController;
  late final Animation<double> _successAnim;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _workMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  void _setMode(_TimerMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _isRunning = false;
      _showSuccess = false;
      _totalSeconds = _modeDuration(mode) * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  int _modeDuration(_TimerMode mode) {
    switch (mode) {
      case _TimerMode.work:
        return _workMinutes;
      case _TimerMode.shortBreak:
        return _shortBreakMinutes;
      case _TimerMode.longBreak:
        return _longBreakMinutes;
    }
  }

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _showSuccess = true;
            if (_mode == _TimerMode.work) {
              _completedSessions++;
              // Award XP for completing a focus session
              if (mounted) {
                context.read<UserProvider>().awardXp(15);
              }
            }
          });
          _successController.forward(from: 0);
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _showSuccess = false;
      _remainingSeconds = _totalSeconds;
    });
    _successController.reset();
  }

  double get _progress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0;

  String get _timeString {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final modeColor = _modeColor(colorScheme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Focus Timer'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                '$_completedSessions 🍅',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Mode selector chips
              _ModeSelector(
                currentMode: _mode,
                onModeChanged: _setMode,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 48),
              // Circular timer with progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow / shadow container
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withAlpha(51),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Circular progress
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(modeColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Timer content
                  if (_showSuccess)
                    ScaleTransition(
                      scale: _successAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: modeColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mode == _TimerMode.work
                                ? 'Session done! 🎉'
                                : 'Break over!',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeString,
                          style: GoogleFonts.outfit(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          _modeLabel(_mode),
                          style: textTheme.bodyMedium?.copyWith(
                            color: modeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 48),
              // Start / Pause button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _showSuccess ? null : _startPause,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRunning
                        ? colorScheme.errorContainer
                        : modeColor,
                    foregroundColor: _isRunning
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(_isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(
                    _isRunning ? 'Pause' : 'Start Focus',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Reset button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Reset',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Tips card
              _TipsCard(
                mode: _mode,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _modeColor(ColorScheme colorScheme) {
    switch (_mode) {
      case _TimerMode.work:
        return colorScheme.primary;
      case _TimerMode.shortBreak:
        return colorScheme.tertiary;
      case _TimerMode.longBreak:
        return colorScheme.secondary;
    }
  }

  String _modeLabel(_TimerMode mode) {
    switch (mode) {
      case _TimerMode.work:
        return 'Focus Session';
      case _TimerMode.shortBreak:
        return 'Short Break';
      case _TimerMode.longBreak:
        return 'Long Break';
    }
  }
}

enum _TimerMode { work, shortBreak, longBreak }

/// Row of segmented-style chips for selecting timer mode.
class _ModeSelector extends StatelessWidget {
  final _TimerMode currentMode;
  final void Function(_TimerMode) onModeChanged;
  final ColorScheme colorScheme;

  const _ModeSelector({
    required this.currentMode,
    required this.onModeChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeChip(
            label: 'Focus',
            mode: _TimerMode.work,
            currentMode: currentMode,
            colorScheme: colorScheme,
            onTap: onModeChanged,
          ),
          _ModeChip(
            label: 'Short Break',
            mode: _TimerMode.shortBreak,
            currentMode: currentMode,
            colorScheme: colorScheme,
            onTap: onModeChanged,
          ),
          _ModeChip(
            label: 'Long Break',
            mode: _TimerMode.longBreak,
            currentMode: currentMode,
            colorScheme: colorScheme,
            onTap: onModeChanged,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final _TimerMode mode;
  final _TimerMode currentMode;
  final ColorScheme colorScheme;
  final void Function(_TimerMode) onTap;

  const _ModeChip({
    required this.label,
    required this.mode,
    required this.currentMode,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Info card showing tips for the current timer mode.
class _TipsCard extends StatelessWidget {
  final _TimerMode mode;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _TipsCard({
    required this.mode,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (mode) {
      _TimerMode.work => (
          Icons.tips_and_updates_outlined,
          'Stay focused',
          'Silence notifications, close unnecessary tabs, and focus solely on '
              'your current task for the next 25 minutes.',
        ),
      _TimerMode.shortBreak => (
          Icons.self_improvement_outlined,
          'Take a quick rest',
          'Stand up, stretch, grab some water, or just relax your eyes. '
              'A short break re-energises your brain!',
        ),
      _TimerMode.longBreak => (
          Icons.hotel_outlined,
          'You earned it!',
          'After 4 Pomodoros it\'s time for a proper break. '
              'Take a walk, have a snack, or do something you enjoy.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withAlpha(153),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
