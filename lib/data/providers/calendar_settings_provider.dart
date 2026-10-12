import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_settings.dart';

const String _calendarSettingsKey = 'calendar_settings';

class CalendarSettingsNotifier extends StateNotifier<CalendarSettings> {
  int _revision = 0;
  Future<void> _pendingSave = Future<void>.value();

  CalendarSettingsNotifier() : super(const CalendarSettings()) {
    _load();
  }

  Future<void> _load() async {
    final revisionAtStart = _revision;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calendarSettingsKey);

    if (_revision != revisionAtStart || raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = CalendarSettings.fromPrefs(map);
    } catch (_) {
      state = const CalendarSettings();
      await _save(state);
    }
  }

  Future<void> _save(CalendarSettings settings) async {
    _pendingSave = _pendingSave.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _calendarSettingsKey,
        jsonEncode(settings.toPrefs()),
      );
    });
    await _pendingSave;
  }

  Future<void> setSync(bool value) async {
    _revision++;
    final next = state.copyWith(syncGoogle: value);
    state = next;
    await _save(next);
  }

  Future<void> setReminder(int value) async {
    _revision++;
    final next = state.copyWith(reminderMinutes: value);
    state = next;
    await _save(next);
  }

  Future<void> setWorkingHours(TimeOfDay start, TimeOfDay end) async {
    _revision++;
    final next = state.copyWith(workStart: start, workEnd: end);
    state = next;
    await _save(next);
  }
}

final calendarSettingsProvider =
    StateNotifierProvider<CalendarSettingsNotifier, CalendarSettings>((ref) {
  return CalendarSettingsNotifier();
});
