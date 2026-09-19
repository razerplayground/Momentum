import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/workspace_model.dart';

/// Exception thrown when API requests fail
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

/// Provider for ApiService singleton
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Single REST Service to manage all API requests, authentication headers,
/// token refresh, and Auth & Workspace endpoints.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ─── Token Management Helpers ─────────────────────────────────────

  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  String? get accessToken => _settingsBox.get(ApiConstants.accessTokenKey) as String?;
  String? get refreshToken => _settingsBox.get(ApiConstants.refreshTokenKey) as String?;

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _settingsBox.put(ApiConstants.accessTokenKey, access);
    if (refresh != null) {
      await _settingsBox.put(ApiConstants.refreshTokenKey, refresh);
    }
  }

  Future<void> saveUserData(UserModel user) async {
    await _settingsBox.put(ApiConstants.userDataKey, jsonEncode(user.toJson()));
  }

  UserModel? getSavedUserData() {
    final raw = _settingsBox.get(ApiConstants.userDataKey) as String?;
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _settingsBox.delete(ApiConstants.accessTokenKey);
    await _settingsBox.delete(ApiConstants.refreshTokenKey);
    await _settingsBox.delete(ApiConstants.userDataKey);
  }

  Map<String, String> _buildHeaders({bool requiresAuth = true}) {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    if (requiresAuth && accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final fullUrl = ApiConstants.baseUrl + endpoint;
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // ─── Core HTTP Handler with Automatic Token Refresh ──────────────

  Future<dynamic> _sendRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final headers = _buildHeaders(requiresAuth: requiresAuth);

    http.Response response;
    try {
      final jsonBody = body != null ? jsonEncode(body) : null;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(ApiConstants.timeoutDuration);
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: jsonBody).timeout(ApiConstants.timeoutDuration);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: jsonBody).timeout(ApiConstants.timeoutDuration);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: jsonBody).timeout(ApiConstants.timeoutDuration);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers, body: jsonBody).timeout(ApiConstants.timeoutDuration);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error or server unreachable: $e');
    }

    // Handle 401 Unauthorized token refresh logic
    if (response.statusCode == 401 && requiresAuth && !isRetry && refreshToken != null) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        return _sendRequest(
          method,
          endpoint,
          body: body,
          queryParams: queryParams,
          requiresAuth: requiresAuth,
          isRetry: true,
        );
      } else {
        await clearSession();
        throw ApiException('Session expired. Please log in again.', statusCode: 401);
      }
    }

    return _processResponse(response);
  }

  Future<bool> _attemptTokenRefresh() async {
    final currentRefreshToken = refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) return false;

    try {
      final uri = _buildUri(ApiConstants.refresh);
      final response = await _client.post(
        uri,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      ).timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String? ?? currentRefreshToken;
        if (newAccess != null) {
          await saveTokens(access: newAccess, refresh: newRefresh);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;

    // 204 No Content
    if (statusCode == 204) {
      return null;
    }

    dynamic decodedBody;
    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        decodedBody = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    String errorMsg = 'HTTP Request failed with status code $statusCode';
    if (decodedBody is Map<String, dynamic>) {
      if (decodedBody.containsKey('message')) {
        final msg = decodedBody['message'];
        errorMsg = msg is List ? msg.join(', ') : msg.toString();
      } else if (decodedBody.containsKey('error')) {
        errorMsg = decodedBody['error'].toString();
      }
    }

    throw ApiException(errorMsg, statusCode: statusCode, body: decodedBody);
  }

  // Generic Public Helper Methods
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, bool requiresAuth = true}) =>
      _sendRequest('GET', endpoint, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('POST', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> patch(String endpoint, {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('PATCH', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> put(String endpoint, {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('PUT', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> delete(String endpoint, {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('DELETE', endpoint, body: body, requiresAuth: requiresAuth);

  // ─── AUTH SERVICES ───────────────────────────────────────────────

  /// Login user with email & password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    if (response is Map<String, dynamic>) {
      final access = response['accessToken'] as String?;
      final refresh = response['refreshToken'] as String?;
      if (access != null) {
        await saveTokens(access: access, refresh: refresh);
      }

      UserModel? user;
      if (response.containsKey('user') && response['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        await saveUserData(user);
      } else {
        // Fetch current user details if not returned directly in login
        try {
          user = await getMe();
        } catch (_) {}
      }

      return {
        'accessToken': access,
        'refreshToken': refresh,
        'user': user,
      };
    }
    throw ApiException('Invalid server response format for login');
  }

  /// Signup new user account
  Future<dynamic> signup({
    required String name,
    required String email,
    required String password,
    String plan = 'individual',
    String? organizationName,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'plan': plan,
    };
    if (plan == 'organization' && organizationName != null) {
      body['organizationName'] = organizationName;
    }

    return await post(
      ApiConstants.signup,
      body: body,
      requiresAuth: false,
    );
  }

  /// Logout user and invalidate refresh token session
  Future<void> logout() async {
    final currentRefresh = refreshToken;
    if (currentRefresh != null && currentRefresh.isNotEmpty) {
      try {
        await post(
          ApiConstants.logout,
          body: {'refreshToken': currentRefresh},
          requiresAuth: false,
        );
      } catch (e) {
        debugPrint('Logout remote call failed: $e');
      }
    }
    await clearSession();
  }

  /// Get current user profile details
  Future<UserModel> getMe() async {
    final res = await get(ApiConstants.me, requiresAuth: true);
    if (res is Map<String, dynamic>) {
      final user = UserModel.fromJson(res);
      await saveUserData(user);
      return user;
    }
    throw ApiException('Failed to parse user profile response');
  }

  /// Update current user profile
  Future<UserModel> updateMe({String? name, String? avatarUrl, String? phoneNumber}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final res = await patch(ApiConstants.me, body: body, requiresAuth: true);
    if (res is Map<String, dynamic>) {
      final user = UserModel.fromJson(res);
      await saveUserData(user);
      return user;
    }
    throw ApiException('Failed to update user profile');
  }

  /// Request password reset email
  Future<void> forgotPassword(String email) async {
    await post(
      ApiConstants.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Reset password using token
  Future<void> resetPassword(String token, String newPassword) async {
    await post(
      ApiConstants.resetPassword,
      body: {'token': token, 'newPassword': newPassword},
      requiresAuth: false,
    );
  }

  // ─── WORKSPACE & BUSINESS SERVICES ───────────────────────────────

  /// Fetch all accessible workspaces & businesses for current user
  Future<List<WorkspaceModel>> getWorkspaces() async {
    final List<WorkspaceModel> workspacesList = [];

    try {
      // 1. Fetch from /v1/workspaces endpoint
      final wsRes = await get(ApiConstants.workspaces, requiresAuth: true);
      if (wsRes is List) {
        for (final item in wsRes) {
          if (item is Map<String, dynamic>) {
            workspacesList.add(WorkspaceModel.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching /v1/workspaces: $e');
    }

    try {
      // 2. Fetch from /v1/businesses endpoint
      final bizRes = await get(ApiConstants.businesses, requiresAuth: true);
      if (bizRes is List) {
        for (final item in bizRes) {
          if (item is Map<String, dynamic>) {
            final model = WorkspaceModel.fromJson(item);
            if (!workspacesList.any((w) => w.id == model.id)) {
              workspacesList.add(model);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching /v1/businesses: $e');
    }

    return workspacesList;
  }

  /// Create a new workspace / business
  Future<WorkspaceModel> createWorkspace({
    required String name,
    String? industry,
    String? address,
    String? contactEmail,
    int? foundedYear,
    String emoji = '🏢',
    int colorValue = 0xFF6C5CE7,
    String description = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (industry != null) 'industry': industry,
      if (address != null || description.isNotEmpty) 'address': address ?? description,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (foundedYear != null) 'foundedYear': foundedYear,
    };

    dynamic res;
    try {
      res = await post(ApiConstants.workspaces, body: body, requiresAuth: true);
    } catch (e) {
      // Fallback to /v1/businesses endpoint if /v1/workspaces fails
      res = await post(ApiConstants.businesses, body: body, requiresAuth: true);
    }

    if (res is Map<String, dynamic>) {
      final workspace = WorkspaceModel.fromJson(res);
      // Ensure local visual properties like emoji/colorValue are preserved
      return workspace.copyWith(
        emoji: emoji,
        colorValue: colorValue,
        description: description.isNotEmpty ? description : workspace.description,
      );
    }

    throw ApiException('Failed to create workspace');
  }

  /// Get single workspace details
  Future<WorkspaceModel> getWorkspaceDetail(String workspaceId) async {
    final res = await get(ApiConstants.workspaceDetail(workspaceId), requiresAuth: true);
    if (res is Map<String, dynamic>) {
      return WorkspaceModel.fromJson(res);
    }
    throw ApiException('Failed to retrieve workspace details');
  }

  /// Update workspace details
  Future<WorkspaceModel> updateWorkspace(
    String workspaceId, {
    String? name,
    String? industry,
    String? address,
    String? contactEmail,
    int? foundedYear,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (industry != null) 'industry': industry,
      if (address != null) 'address': address,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (foundedYear != null) 'foundedYear': foundedYear,
    };

    final res = await patch(ApiConstants.workspaceDetail(workspaceId), body: body, requiresAuth: true);
    if (res is Map<String, dynamic>) {
      return WorkspaceModel.fromJson(res);
    }
    throw ApiException('Failed to update workspace');
  }

  /// Delete workspace
  Future<void> deleteWorkspace(String workspaceId) async {
    await delete(ApiConstants.workspaceDetail(workspaceId), requiresAuth: true);
  }
}
