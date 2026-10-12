import 'package:flutter/material.dart';

class CalendarSettings {
  final bool syncGoogle;
  final int reminderMinutes;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;

  const CalendarSettings({
    this.syncGoogle = true,
    this.reminderMinutes = 15,
    this.workStart = const TimeOfDay(hour: 9, minute: 0),
    this.workEnd = const TimeOfDay(hour: 17, minute: 0),
  });

  CalendarSettings copyWith({
    bool? syncGoogle,
    int? reminderMinutes,
    TimeOfDay? workStart,
    TimeOfDay? workEnd,
  }) {
    return CalendarSettings(
      syncGoogle: syncGoogle ?? this.syncGoogle,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      workStart: workStart ?? this.workStart,
      workEnd: workEnd ?? this.workEnd,
    );
  }

  Map<String, dynamic> toPrefs() {
    return {
      'syncGoogle': syncGoogle,
      'reminderMinutes': reminderMinutes,
      'workStart': _timeOfDayToMinutes(workStart),
      'workEnd': _timeOfDayToMinutes(workEnd),
    };
  }

  static CalendarSettings fromPrefs(Map<String, dynamic> json) {
    final workStartMinutes = json['workStart'] as int? ?? 9 * 60;
    final workEndMinutes = json['workEnd'] as int? ?? 17 * 60;

    return CalendarSettings(
      syncGoogle: json['syncGoogle'] as bool? ?? true,
      reminderMinutes: json['reminderMinutes'] as int? ?? 15,
      workStart: _minutesToTimeOfDay(workStartMinutes),
      workEnd: _minutesToTimeOfDay(workEndMinutes),
    );
  }

  static int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static TimeOfDay _minutesToTimeOfDay(int minutes) {
    final normalized = minutes.clamp(0, 23 * 60 + 59);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }
}
