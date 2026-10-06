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
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
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

  // â”€â”€â”€ Token Management Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  String? get accessToken =>
      _settingsBox.get(ApiConstants.accessTokenKey) as String?;
  String? get refreshToken =>
      _settingsBox.get(ApiConstants.refreshTokenKey) as String?;

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
    final token = accessToken?.trim();
    if (requiresAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
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

  // â”€â”€â”€ Core HTTP Handler with Automatic Token Refresh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          response = await _client
              .get(uri, headers: headers)
              .timeout(ApiConstants.timeoutDuration);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonBody)
              .timeout(ApiConstants.timeoutDuration);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonBody)
              .timeout(ApiConstants.timeoutDuration);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonBody)
              .timeout(ApiConstants.timeoutDuration);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers, body: jsonBody)
              .timeout(ApiConstants.timeoutDuration);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error or server unreachable: $e');
    }

    // Handle 401 Unauthorized token refresh logic
    if (response.statusCode == 401 &&
        requiresAuth &&
        !isRetry &&
        refreshToken != null) {
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
        throw ApiException('Session expired. Please log in again.',
            statusCode: 401);
      }
    }

    return _processResponse(response);
  }

  Future<bool> _attemptTokenRefresh() async {
    final currentRefreshToken = refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty)
      return false;

    try {
      final uri = _buildUri(ApiConstants.refresh);
      final response = await _client
          .post(
            uri,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({'refreshToken': currentRefreshToken}),
          )
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh =
            data['refreshToken'] as String? ?? currentRefreshToken;
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
  Future<dynamic> get(String endpoint,
          {Map<String, String>? queryParams, bool requiresAuth = true}) =>
      _sendRequest('GET', endpoint,
          queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> post(String endpoint,
          {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('POST', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> patch(String endpoint,
          {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('PATCH', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> put(String endpoint,
          {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('PUT', endpoint, body: body, requiresAuth: requiresAuth);

  Future<dynamic> delete(String endpoint,
          {dynamic body, bool requiresAuth = true}) =>
      _sendRequest('DELETE', endpoint, body: body, requiresAuth: requiresAuth);

  // â”€â”€â”€ AUTH SERVICES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Login user with email & password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final savedUser = getSavedUserData();
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
      if (response.containsKey('user') &&
          response['user'] is Map<String, dynamic>) {
        user = _preserveSavedPlan(
          UserModel.fromJson(response['user'] as Map<String, dynamic>),
          savedUser,
        );
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
      final user = _preserveSavedPlan(
        UserModel.fromJson(res),
        getSavedUserData(),
      );
      await saveUserData(user);
      return user;
    }
    throw ApiException('Failed to parse user profile response');
  }

  /// Update current user profile
  Future<UserModel> updateMe(
      {String? name, String? avatarUrl, String? phoneNumber}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final res = await patch(ApiConstants.me, body: body, requiresAuth: true);
    if (res is Map<String, dynamic>) {
      final user = _preserveSavedPlan(
        UserModel.fromJson(res),
        getSavedUserData(),
      );
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

  UserModel _preserveSavedPlan(UserModel user, UserModel? savedUser) {
    final plan = user.plan?.trim().isNotEmpty == true
        ? user.plan
        : savedUser?.plan;
    final organizationName = user.organizationName?.trim().isNotEmpty == true
        ? user.organizationName
        : savedUser?.organizationName;
    return user.copyWith(
      plan: plan,
      organizationName: organizationName,
    );
  }

  // â”€â”€â”€ WORKSPACE & BUSINESS SERVICES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    String emoji = 'ðŸ¢',
    int colorValue = 0xFF6C5CE7,
    String description = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (industry != null) 'industry': industry,
      if (address != null || description.isNotEmpty)
        'address': address ?? description,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (foundedYear != null) 'foundedYear': foundedYear,
    };

    final response = await post(
      ApiConstants.businesses,
      body: body,
      requiresAuth: true,
    );
    final business = _businessResponseMap(response);
    final businessId = (business?['id'] ?? business?['_id'])?.toString();
    if (business == null || businessId == null || businessId.isEmpty) {
      throw ApiException(
        'Business was created, but the server did not return its ID. Refresh businesses before retrying.',
      );
    }

    final workspace = WorkspaceModel.fromJson(business);
    return workspace.copyWith(
      emoji: emoji,
      colorValue: colorValue,
      description:
          description.isNotEmpty ? description : workspace.description,
    );
  }

  Map<String, dynamic>? _businessResponseMap(dynamic response) {
    dynamic business = response;
    for (var depth = 0; depth < 3; depth++) {
      if (business is! Map<String, dynamic>) return null;
      final nested =
          business['business'] ?? business['workspace'] ?? business['data'];
      if (nested is Map<String, dynamic>) {
        business = nested;
      } else {
        return business;
      }
    }
    return business is Map<String, dynamic> ? business : null;
  }

  /// Get single workspace details
  Future<WorkspaceModel> getWorkspaceDetail(String workspaceId) async {
    final res = await get(ApiConstants.workspaceDetail(workspaceId),
        requiresAuth: true);
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

    final res = await patch(ApiConstants.workspaceDetail(workspaceId),
        body: body, requiresAuth: true);
    if (res is Map<String, dynamic>) {
      return WorkspaceModel.fromJson(res);
    }
    throw ApiException('Failed to update workspace');
  }

  /// Delete workspace
  Future<void> deleteWorkspace(String workspaceId) async {
    await delete(ApiConstants.workspaceDetail(workspaceId), requiresAuth: true);
  }

  /// Fetch employees for a business.
  Future<List<Map<String, dynamic>>> getEmployees(String businessId) async {
    final response =
        await get(ApiConstants.employees(businessId), requiresAuth: true);
    dynamic items = response;
    if (response == null) return [];
    if (items is Map<String, dynamic>) {
      items = items['employees'] ?? items['data'] ?? items['items'] ?? items;
      if (items is Map<String, dynamic>) {
        items = items['employees'] ?? items['items'] ?? items['data'];
      }
    }
    if (items is! List) {
      throw ApiException('Failed to retrieve employees');
    }
    return items.whereType<Map<String, dynamic>>().toList();
  }

  /// Create an employee for a business.
  Future<Map<String, dynamic>> createEmployee(
    String businessId,
    Map<String, dynamic> body,
  ) async {
    final response = await post(ApiConstants.employees(businessId),
        body: body, requiresAuth: true);
    final employee = _employeeResponseMap(response);
    if (employee != null &&
        ((employee['id'] ?? employee['_id'])?.toString().isNotEmpty ?? false)) {
      return employee;
    }

    final email = body['email']?.toString().trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final employees = await getEmployees(businessId);
      for (final created in employees) {
        if (created['email']?.toString().trim().toLowerCase() == email) {
          return created;
        }
      }
    }

    throw ApiException(
      'Employee creation succeeded, but the server did not return the new employee. Refresh the employee list and try again.',
    );
  }

  /// Update an employee for a business.
  Future<void> updateEmployee(
    String businessId,
    String employeeId,
    Map<String, dynamic> body,
  ) async {
    await patch(ApiConstants.employeeDetail(businessId, employeeId),
        body: body, requiresAuth: true);
  }

  /// Delete an employee for a business.
  Future<void> deleteEmployee(String businessId, String employeeId) async {
    await delete(ApiConstants.employeeDetail(businessId, employeeId),
        requiresAuth: true);
  }

  /// Fetch jobs for a business.
  Future<List<Map<String, dynamic>>> getJobs(String businessId) async {
    final response =
        await get(ApiConstants.jobs(businessId), requiresAuth: true);
    if (response == null) return [];
    dynamic items = response;
    for (var depth = 0; depth < 3 && items is Map<String, dynamic>; depth++) {
      final nested = items['jobs'] ?? items['items'] ?? items['data'];
      if (nested == null) {
        throw ApiException('Failed to retrieve jobs');
      }
      items = nested;
    }
    if (items is! List) {
      throw ApiException('Failed to retrieve jobs');
    }
    return items.whereType<Map<String, dynamic>>().toList();
  }

  /// Create a job for a business.
  Future<Map<String, dynamic>> createJob(
    String businessId,
    Map<String, dynamic> body,
  ) async {
    final response = await post(ApiConstants.jobs(businessId),
        body: body, requiresAuth: true);
    var job = _jobResponseMap(response);
    if (job == null) {
      final jobs = await getJobs(businessId);
      for (final created in jobs) {
        if (created['title']?.toString() == body['title']?.toString() &&
            created['department']?.toString() ==
                body['department']?.toString() &&
            created['status']?.toString() == body['status']?.toString()) {
          job = created;
        }
      }
    }
    if (job == null) {
      throw ApiException(
        'Job creation succeeded, but the new job could not be found. Refresh the job list before retrying.',
      );
    }
    return {...body, ...job};
  }

  /// Update a job for a business.
  Future<void> updateJob(
    String businessId,
    String jobId,
    Map<String, dynamic> body,
  ) async {
    await patch(ApiConstants.jobDetail(businessId, jobId),
        body: body, requiresAuth: true);
  }

  /// Delete a job from a business.
  Future<void> deleteJob(String businessId, String jobId) async {
    await delete(ApiConstants.jobDetail(businessId, jobId), requiresAuth: true);
  }

  Map<String, dynamic>? _jobResponseMap(dynamic response) {
    dynamic job = response;
    for (var depth = 0; depth < 3; depth++) {
      if (job is! Map<String, dynamic>) return null;
      final nested = job['job'] ?? job['data'] ?? job['item'];
      if (nested is Map<String, dynamic>) {
        job = nested;
      } else {
        return (job['id'] ?? job['_id']) != null ? job : null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _employeeResponseMap(dynamic response) {
    dynamic employee = response;
    for (var depth = 0; depth < 3; depth++) {
      if (employee is! Map<String, dynamic>) return null;
      final nested =
          employee['employee'] ?? employee['data'] ?? employee['item'];
      if (nested is Map<String, dynamic>) {
        employee = nested;
      } else {
        return employee;
      }
    }
    return employee is Map<String, dynamic> ? employee : null;
  }

  /// Fetch payroll entries for a business.
  Future<List<Map<String, dynamic>>> getPayroll(String businessId) async {
    final response =
        await get(ApiConstants.payrollList(businessId), requiresAuth: true);
    if (response == null) return [];

    dynamic entries = response;
    for (var depth = 0;
        depth < 3 && entries is Map<String, dynamic>;
        depth++) {
      final nested =
          entries['payroll'] ?? entries['entries'] ?? entries['items'] ?? entries['data'];
      if (nested == null) {
        throw ApiException('Failed to retrieve payroll entries');
      }
      entries = nested;
    }
    if (entries is! List) {
      throw ApiException('Failed to retrieve payroll entries');
    }
    return entries.whereType<Map<String, dynamic>>().toList();
  }

  /// Fetch payroll summary for a business.
  Future<Map<String, dynamic>> getPayrollSummary(String businessId) async {
    final response = await get(
      ApiConstants.payrollSummary(businessId),
      requiresAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw ApiException('Failed to retrieve payroll summary');
    }

    dynamic summary = response;
    for (var depth = 0; depth < 3 && summary is Map<String, dynamic>; depth++) {
      final nested = summary['summary'] ?? summary['data'];
      if (nested is Map<String, dynamic>) {
        summary = nested;
      } else {
        return summary;
      }
    }
    if (summary is Map<String, dynamic>) return summary;
    throw ApiException('Failed to retrieve payroll summary');
  }

  /// Run payroll for a business using the server's payroll-run payload.
  Future<dynamic> runPayroll(
    String businessId,
    Map<String, dynamic> body,
  ) async {
    return post(
      ApiConstants.payrollRun(businessId),
      body: body,
      requiresAuth: true,
    );
  }

  /// Update a payroll entry for a business.
  Future<void> updatePayrollEntry(
    String businessId,
    String entryId,
    Map<String, dynamic> body,
  ) async {
    await patch(
      ApiConstants.payrollEntryDetail(businessId, entryId),
      body: body,
      requiresAuth: true,
    );
  }

  /// Delete a payroll entry from a business.
  Future<void> deletePayrollEntry(String businessId, String entryId) async {
    await delete(
      ApiConstants.payrollEntryDetail(businessId, entryId),
      requiresAuth: true,
    );
  }

  /// Fetch report metrics across all businesses accessible to the user.
  Future<dynamic> getOrganizationReportOverview() {
    return get(ApiConstants.reportsOverview, requiresAuth: true);
  }

  /// Fetch the overview report for a single business.
  Future<dynamic> getBusinessReport(String businessId) {
    return get(ApiConstants.businessReport(businessId), requiresAuth: true);
  }

  /// Fetch monthly income-versus-expense data for a business.
  Future<dynamic> getFinancialTrend(String businessId) {
    return get(ApiConstants.financialTrend(businessId), requiresAuth: true);
  }

  /// Fetch project progress and task breakdown data for a business.
  Future<dynamic> getProjectAnalytics(String businessId) {
    return get(ApiConstants.projectAnalytics(businessId), requiresAuth: true);
  }

  /// Fetch recent activity records for a business.
  Future<dynamic> getAuditLogs(String businessId) {
    return get(ApiConstants.auditLogs(businessId), requiresAuth: true);
  }

  /// Export financial records in CSV format.
  Future<dynamic> exportFinances(String businessId) {
    return get(ApiConstants.exportFinances(businessId), requiresAuth: true);
  }

  /// Export payroll records in CSV format.
  Future<dynamic> exportPayroll(String businessId) {
    return get(ApiConstants.exportPayroll(businessId), requiresAuth: true);
  }

  /// Export employee roster in CSV format.
  Future<dynamic> exportEmployees(String businessId) {
    return get(ApiConstants.exportEmployees(businessId), requiresAuth: true);
  }

  /// Upload a file to storage as a multipart request.
  Future<dynamic> uploadStorageFile(String filename, Uint8List bytes,
      {bool isRetry = false}) async {
    if (filename.trim().isEmpty) {
      throw ApiException('A filename is required to upload a file');
    }
    if (bytes.isEmpty) {
      throw ApiException('Cannot upload an empty file');
    }

    final request = http.MultipartRequest(
      'POST',
      _buildUri(ApiConstants.uploadFile),
    );
    for (final header in _buildHeaders().entries) {
      if (header.key.toLowerCase() != 'content-type') {
        request.headers[header.key] = header.value;
      }
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    http.Response response;
    try {
      final streamedResponse =
          await _client.send(request).timeout(ApiConstants.timeoutDuration);
      response = await http.Response.fromStream(streamedResponse)
          .timeout(ApiConstants.timeoutDuration);
    } catch (e) {
      throw ApiException('Network error or server unreachable: $e');
    }

    if (response.statusCode == 401 &&
        !isRetry &&
        refreshToken != null) {
      if (await _attemptTokenRefresh()) {
        return uploadStorageFile(filename, bytes, isRetry: true);
      }
      await clearSession();
      throw ApiException('Session expired. Please log in again.',
          statusCode: 401);
    }

    return _processResponse(response);
  }

  /// Download a stored file as its original bytes.
  Future<Uint8List> downloadStorageFile(String filename,
      {bool isRetry = false}) async {
    if (filename.trim().isEmpty) {
      throw ApiException('A filename is required to download a file');
    }

    http.Response response;
    try {
      response = await _client
          .get(
            _buildUri(ApiConstants.getFile(filename)),
            headers: {
              ..._buildHeaders(),
              'Accept': '*/*',
            },
          )
          .timeout(ApiConstants.timeoutDuration);
    } catch (e) {
      throw ApiException('Network error or server unreachable: $e');
    }

    if (response.statusCode == 401 &&
        !isRetry &&
        refreshToken != null) {
      if (await _attemptTokenRefresh()) {
        return downloadStorageFile(filename, isRetry: true);
      }
      await clearSession();
      throw ApiException('Session expired. Please log in again.',
          statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _processResponse(response);
    }
    return response.bodyBytes;
  }
}
