import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pass this key to GoRouter(navigatorKey: rootNavigatorKey, ...).
final rootNavigatorKey = GlobalKey<NavigatorState>();

bool _dialogShowing = false;

/// Shows a "session expired" popup (only once at a time), then sends the
/// user to the login screen.
void showSessionExpiredDialog() {
  if (_dialogShowing) return;
  final overlayContext = rootNavigatorKey.currentState?.overlay?.context;
  if (overlayContext == null) return;

  _dialogShowing = true;
  showDialog<void>(
    context: overlayContext,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Session expired'),
        content: const Text('Your session has expired. Please log in again.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Log in'),
          ),
        ],
      ),
    ),
  ).then((_) {
    _dialogShowing = false;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) GoRouter.of(ctx).go('/login');
  });
}