import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmedValue = (value ?? '').trim();
    if (trimmedValue.isEmpty) {
      return 'Email is required.';
    }
    if (!AuthService.isValidEmail(trimmedValue)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Password is required.';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    final success = await ref.read(authProvider.notifier).login(
          email: email,
          password: pass,
        );

    if (!mounted) return;

    if (success) {
      // Sync local AuthService session email
      await AuthService.setSessionEmail(email);
      await ref.read(workspacesProvider.notifier).loadWorkspaces();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      context.go('/workspaces');
    } else {
      final error =
          ref.read(authProvider).errorMessage ?? 'Invalid email or password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Opens the Forgot Password bottom sheet. Returns true if the reset
  /// request was sent successfully.
  Future<void> _openForgotPassword() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ForgotPasswordSheet(initialEmail: _emailCtrl.text.trim()),
    );

    if (!mounted) return;

    if (sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'If this email is registered, a reset link/code has been sent.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Welcome Back 👋', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to BizPro.',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                Text('Email', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  enabled: !authState.isLoading,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscureText,
                  validator: _validatePassword,
                  enabled: !authState.isLoading,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading ? null : _openForgotPassword,
                    child: Text('Forgot Password?',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 32),
                if (authState.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else
                  GradientButton(
                    label: 'Login',
                    onTap: _login,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.go('/signup'),
                      child: Text('Sign Up',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Forgot Password bottom sheet (kept in this file so no extra screen/route
// is needed). Calls POST /v1/auth/forgot-password with { "email": ... }.
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required.';
    if (!AuthService.isValidEmail(v)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}'),
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({'email': _emailCtrl.text.trim()}),
          )
          .timeout(ApiConstants.timeoutDuration);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Navigator.of(context).pop(true); // login screen shows the snackbar
        return;
      }

      var message = 'Something went wrong. Please try again.';
      try {
        final body = jsonDecode(response.body);
        final m = body['message'];
        if (m is String) message = m;
        if (m is List && m.isNotEmpty) message = m.first.toString();
      } catch (_) {}
      setState(() => _errorText = message);
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _errorText = 'Network error. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Forgot Password? 🔑', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you instructions to reset your password.",
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text('Email', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              enabled: !_isLoading,
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon:
                    const Icon(Icons.email_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              GradientButton(label: 'Send Reset Link', onTap: _submit),
          ],
        ),
      ),
    );
  }
}