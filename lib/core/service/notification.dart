import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Outcome of trying to schedule an appointment reminder.
enum ReminderResult {
  /// Reminder was scheduled.
  scheduled,

  /// Nothing to do: reminder is off ("No reminder") or the appointment
  /// has already started.
  skipped,

  /// The user has notifications turned off for the app.
  notificationsBlocked,

  /// Scheduling failed for another reason.
  failed,
}

/// Schedules alarm-style local reminders for appointments.
/// Written for flutter_local_notifications ^22.x (named-parameter API).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _permissionsAsked = false;

  static const String _channelId = 'appointment_reminders';
  static const String _channelName = 'Appointment Reminders';
  static const String _channelDesc = 'Reminders for your scheduled appointments';

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  /// Call once in main() before runApp().
  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _android?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Asks for notification permission, and for exact-alarm permission only
  /// when it is missing. Asked once per app run so the user is not bounced
  /// to system settings every time an appointment is saved.
  static Future<void> requestPermissions() async {
    await init();
    if (_permissionsAsked) return;
    _permissionsAsked = true;

    final android = _android;
    await android?.requestNotificationsPermission();

    final canExact = await android?.canScheduleExactNotifications() ?? true;
    if (!canExact) {
      await android?.requestExactAlarmsPermission();
    }

    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Stable id (same input -> same id across app restarts) so a reminder can
  /// be cancelled or replaced later. Dart's String.hashCode is not guaranteed
  /// to be stable between runs, so we use FNV-1a instead.
  static int idFor(String seed, DateTime start) {
    var hash = 0x811C9DC5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final mixed = hash ^ (start.millisecondsSinceEpoch & 0x7FFFFFFF);
    return mixed & 0x7FFFFFFF;
  }

  static String _bodyText(int leadMinutes, String? location) {
    final String lead;
    if (leadMinutes < 60) {
      lead = 'Starts in $leadMinutes min';
    } else {
      final h = leadMinutes ~/ 60;
      final m = leadMinutes % 60;
      lead = 'Starts in $h hr${m == 0 ? '' : ' $m min'}';
    }
    final loc = (location ?? '').trim();
    return loc.isEmpty ? lead : '$lead • $loc';
  }

  /// Schedules a reminder [reminderMinutes] before [start].
  static Future<ReminderResult> scheduleAppointmentReminder({
    required String seed,
    required String title,
    required DateTime start,
    required int reminderMinutes,
    String? location,
  }) async {
    if (reminderMinutes <= 0) return ReminderResult.skipped;

    final now = DateTime.now();
    if (!start.isAfter(now)) return ReminderResult.skipped;

    try {
      await requestPermissions();

      final enabled = await _android?.areNotificationsEnabled() ?? true;
      if (!enabled) return ReminderResult.notificationsBlocked;

      var remindAt = start.subtract(Duration(minutes: reminderMinutes));
      var leadMinutes = reminderMinutes;
      if (!remindAt.isAfter(now)) {
        // Reminder time already passed but the appointment is still upcoming
        // (e.g. 15-min reminder for a meeting starting in 5 min): remind now.
        remindAt = now.add(const Duration(seconds: 5));
        leadMinutes =
            start.difference(now).inMinutes.clamp(1, reminderMinutes).toInt();
      }

      debugPrint('Reminder for "$title" scheduled at $remindAt');

      // TZDateTime.from keeps the exact instant, so no local-zone setup needed.
      final scheduled = tz.TZDateTime.from(remindAt, tz.UTC);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

      final id = idFor(seed, start);
      final body = _bodyText(leadMinutes, location);

      Future<void> schedule(AndroidScheduleMode mode) {
        return _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      }

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (e) {
        debugPrint('Exact reminder failed ($e), using inexact alarm.');
        // Exact-alarm permission denied: fall back to an inexact alarm.
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
      return ReminderResult.scheduled;
    } catch (e) {
      debugPrint('Reminder scheduling failed: $e');
      return ReminderResult.failed;
    }
  }

  /// Cancels a reminder created with the same [seed] and [start].
  static Future<void> cancel(String seed, DateTime start) async {
    await init();
    await _plugin.cancel(id: idFor(seed, start));
  }
}