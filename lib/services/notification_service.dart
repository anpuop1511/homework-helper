import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for scheduling and displaying local notifications.
///
/// Handles timer completion alerts and assignment deadline reminders.
/// Degrades gracefully on platforms / browsers where notifications are
/// not supported or permission is denied.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification channel / IDs ──────────────────────────────────────────
  static const int _timerDoneId = 1;
  static const int _deadlineBaseId = 100; // offset for deadline notifications

  static const AndroidNotificationDetails _androidTimer =
      AndroidNotificationDetails(
    'timer_channel',
    'Focus Timer',
    channelDescription: 'Alerts when a Pomodoro focus session ends.',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const AndroidNotificationDetails _androidDeadline =
      AndroidNotificationDetails(
    'deadline_channel',
    'Assignment Deadlines',
    channelDescription: 'Reminders about upcoming assignment deadlines.',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  // ── Initialisation ───────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(settings: initSettings);

      // Request permission on Android 13+
      if (!kIsWeb) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      // Notifications are a nice-to-have; don't crash the app if unsupported.
      debugPrint('[NotificationService] init failed: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Shows an immediate notification that the focus timer has completed.
  Future<void> showTimerDone() async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: _timerDoneId,
        title: '🍅 Focus Session Complete!',
        body: 'Great work! Take a short break before your next session.',
        notificationDetails: const NotificationDetails(
          android: _androidTimer,
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showTimerDone failed: $e');
    }
  }

  /// Schedules a reminder notification one hour before [deadline].
  ///
  /// Uses [assignmentId] as the unique notification ID offset so that
  /// multiple deadlines can be tracked independently.
  Future<void> scheduleDeadlineReminder({
    required int assignmentId,
    required String title,
    required DateTime deadline,
  }) async {
    if (!_initialized) return;
    final reminderTime = deadline.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return; // already past

    try {
      await _plugin.zonedSchedule(
        id: _deadlineBaseId + assignmentId,
        title: '📚 Deadline in 1 hour!',
        body: '"$title" is due at ${_formatTime(deadline)}.',
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: NotificationDetails(
          android: _androidDeadline,
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleDeadlineReminder failed: $e');
    }
  }

  /// Cancels the scheduled reminder for [assignmentId].
  Future<void> cancelDeadlineReminder(int assignmentId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _deadlineBaseId + assignmentId);
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
