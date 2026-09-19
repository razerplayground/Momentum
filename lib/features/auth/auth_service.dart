import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

class AuthService {
  AuthService._();

  static const String _registeredUsersKey = 'registered_users';
  static const String _sessionEmailKey = 'session_email';
  static const String _sessionNameKey = 'session_name';

  static Box<dynamic> get _settingsBox => Hive.box(AppConstants.settingsBox);

  static String validateLoginForm({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Email is required.';
    }

    if (!isValidEmail(trimmedEmail)) {
      return 'Please enter a valid email address.';
    }

    if (password.trim().isEmpty) {
      return 'Password is required.';
    }

    return '';
  }

  static String validateSignupForm({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      return 'Full name is required.';
    }

    if (trimmedEmail.isEmpty) {
      return 'Email is required.';
    }

    if (!isValidEmail(trimmedEmail)) {
      return 'Please enter a valid email address.';
    }

    if (password.trim().isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    if (confirmPassword.trim().isEmpty) {
      return 'Please confirm your password.';
    }

    if (confirmPassword != password) {
      return 'Passwords do not match.';
    }

    return '';
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  static bool userExists(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    final users = _getRegisteredUsers();
    return users.any(
      (user) =>
          (user['email'] ?? '').toString().toLowerCase() == normalizedEmail,
    );
  }

  static Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final validationMessage = validateSignupForm(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: password,
    );

    if (validationMessage.isNotEmpty) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final users = _getRegisteredUsers();

    if (users.any(
      (user) =>
          (user['email'] ?? '').toString().toLowerCase() == normalizedEmail,
    )) {
      return false;
    }

    users.add({
      'fullName': fullName.trim(),
      'email': normalizedEmail,
      'passwordHash': _hashPassword(password),
    });

    await _settingsBox.put(_registeredUsersKey, users);
    await _settingsBox.put(_sessionEmailKey, normalizedEmail);
    await _settingsBox.put(_sessionNameKey, fullName.trim());

    return true;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final validationMessage = validateLoginForm(
      email: email,
      password: password,
    );

    if (validationMessage.isNotEmpty) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final users = _getRegisteredUsers();
    final matchingUser = users.firstWhere(
      (user) =>
          (user['email'] ?? '').toString().toLowerCase() == normalizedEmail,
      orElse: () => <String, String>{},
    );

    if (matchingUser.isEmpty) {
      return false;
    }

    final storedHash = matchingUser['passwordHash'] ?? '';
    if (_hashPassword(password) != storedHash) {
      return false;
    }

    await _settingsBox.put(_sessionEmailKey, normalizedEmail);
    await _settingsBox.put(_sessionNameKey, matchingUser['fullName'] ?? '');

    return true;
  }

  static bool isLoggedIn() {
    final sessionEmail =
        (_settingsBox.get(_sessionEmailKey) ?? '').toString().trim();
    return sessionEmail.isNotEmpty;
  }

  static String getSessionEmail() {
    return (_settingsBox.get(_sessionEmailKey) ?? '').toString();
  }

  static Future<void> setSessionEmail(String email, {String? name}) async {
    final normalized = email.trim().toLowerCase();
    await _settingsBox.put(_sessionEmailKey, normalized);
    if (name != null && name.isNotEmpty) {
      await _settingsBox.put(_sessionNameKey, name);
    }
  }

  static String getSessionName() {
    return (_settingsBox.get(_sessionNameKey) ?? '').toString();
  }

  static String userSettingKey(String key) {
    final email = getSessionEmail().trim().toLowerCase();
    return '${key}_$email';
  }

  static bool hasSavedWorkspace() {
    final workspaceId =
        (_settingsBox.get(userSettingKey(AppConstants.activeWorkspaceKey)) ??
                '')
            .toString();
    return workspaceId.isNotEmpty;
  }

  static Future<void> logout() async {
    await _settingsBox.delete(_sessionEmailKey);
    await _settingsBox.delete(_sessionNameKey);
  }

  static List<Map<String, String>> _getRegisteredUsers() {
    final storedUsers = _settingsBox.get(_registeredUsersKey);
    if (storedUsers is! List) {
      return <Map<String, String>>[];
    }

    final normalized = <Map<String, String>>[];
    for (final item in storedUsers) {
      if (item is Map) {
        normalized.add(
          item.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
      }
    }

    return normalized;
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return md5.convert(bytes).toString();
  }
}
