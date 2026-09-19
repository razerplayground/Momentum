import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bussiness_management/core/constants/app_constants.dart';
import 'package:bussiness_management/features/auth/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final tempDir =
        await Directory.systemTemp.createTemp('momentum_auth_test_');
    Hive.init(tempDir.path);

    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      await Hive.openBox(AppConstants.settingsBox);
    }

    final settings = Hive.box(AppConstants.settingsBox);
    await settings.clear();
  });

  test('registers a new user and persists the session', () async {
    final registered = await AuthService.registerUser(
      fullName: 'Jane Doe',
      email: 'jane@example.com',
      password: 'Password123',
    );

    expect(registered, isTrue);
    expect(AuthService.isLoggedIn(), isTrue);
    expect(AuthService.getSessionEmail(), 'jane@example.com');
  });

  test('login succeeds only with valid credentials', () async {
    await AuthService.registerUser(
      fullName: 'Jane Doe',
      email: 'jane@example.com',
      password: 'Password123',
    );

    expect(
        await AuthService.login(
            email: 'jane@example.com', password: 'Password123'),
        isTrue);
    expect(
        await AuthService.login(
            email: 'jane@example.com', password: 'wrongpass'),
        isFalse);
  });

  test('signup validation catches invalid input', () {
    expect(
      AuthService.validateSignupForm(
        fullName: '',
        email: 'not-an-email',
        password: '123',
        confirmPassword: '456',
      ),
      contains('Full name'),
    );
  });
}
