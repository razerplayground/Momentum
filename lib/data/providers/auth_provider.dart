import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    checkAuthStatus();
  }

  /// Initialize auth status from saved tokens and verify with server
  Future<void> checkAuthStatus() async {
    final savedToken = _apiService.accessToken;
    final savedUser = _apiService.getSavedUserData();

    if (savedToken == null || savedToken.isEmpty) {
      state = state.copyWith(isAuthenticated: false, user: null);
      return;
    }

    // Set initial state with local saved user while verifying with API
    state = state.copyWith(
      isAuthenticated: true,
      user: savedUser,
      isLoading: true,
    );

    try {
      final freshUser = await _apiService.getMe();
      state = state.copyWith(
        isAuthenticated: true,
        user: freshUser,
        isLoading: false,
      );
    } catch (e) {
      // If saved user exists, keep offline logged-in state unless 401 error
      if (e is ApiException && e.statusCode == 401) {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: savedUser != null,
          isLoading: false,
        );
      }
    }
  }

  /// Login with email & password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.login(email: email, password: password);
      final user = res['user'] as UserModel?;
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Login failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Signup new user account
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String plan = 'individual',
    String? organizationName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiService.signup(
        name: name,
        email: email,
        password: password,
        plan: plan,
        organizationName: organizationName,
      );

      // Auto login after successful signup
      return await login(email: email, password: password);
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Signup failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _apiService.logout();
    state = const AuthState(isAuthenticated: false, user: null, isLoading: false);
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
