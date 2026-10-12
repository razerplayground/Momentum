import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules alarm-style local reminders for appointments.
/// Written for flutter_local_notifications ^22.x (named-parameter API).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'appointment_reminders';
  static const String _channelName = 'Appointment Reminders';
  static const String _channelDesc = 'Reminders for your scheduled appointments';

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
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Asks for notification + exact alarm permission (Android 13+/14+, iOS).
  static Future<void> requestPermissions() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Stable id so the same appointment can be cancelled/replaced later.
  static int idFor(String seed, DateTime start) {
    return (seed.hashCode ^ start.millisecondsSinceEpoch) & 0x7FFFFFFF;
  }

  /// Schedules a reminder [reminderMinutes] before [start].
  /// Returns false if nothing was scheduled (no reminder set / time passed).
  static Future<bool> scheduleAppointmentReminder({
    required String seed,
    required String title,
    required DateTime start,
    required int reminderMinutes,
    String? location,
  }) async {
    if (reminderMinutes <= 0) return false;

    await init();
    await requestPermissions();

    final now = DateTime.now();
    if (!start.isAfter(now)) return false; // appointment already started

    var remindAt = start.subtract(Duration(minutes: reminderMinutes));
    var leadMinutes = reminderMinutes;
    if (!remindAt.isAfter(now)) {
      // Reminder time already passed but the appointment is still upcoming
      // (e.g. 15-min reminder for a meeting starting in 5 min): remind now.
      remindAt = now.add(const Duration(seconds: 5));
      leadMinutes = start.difference(now).inMinutes.clamp(1, reminderMinutes);
    }

    debugPrint('Reminder for "$title" scheduled at $remindAt');

    // TZDateTime.from keeps the exact instant, so no local-zone setup needed.
    final scheduled = tz.TZDateTime.from(remindAt, tz.UTC);

    final loc = (location ?? '').trim();
    final body = leadMinutes < 60
        ? 'Starts in $leadMinutes min'
        : 'Starts in ${leadMinutes ~/ 60} hr'
            '${leadMinutes % 60 == 0 ? '' : ' ${leadMinutes % 60} min'}';
    final fullBody = loc.isEmpty ? body : '$body • $loc';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
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

    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id: id,
        title: title,
        body: fullBody,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      return true;
    } catch (e) {
      debugPrint('Exact reminder failed: $e');
      // Fall back to inexact alarm if exact alarm permission is denied.
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        return true;
      } catch (e2) {
        debugPrint('Fallback reminder failed: $e2');
        return false;
      }
    }
  }

  static Future<void> cancel(String seed, DateTime start) async {
    await init();
    await _plugin.cancel(id: idFor(seed, start));
  }
}