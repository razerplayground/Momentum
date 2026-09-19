class ApiConstants {
  ApiConstants._();

  // Base URL
  static const String baseUrl = 'http://b8k8o7x7ayujh4mx5z9rbmrc.161.97.134.101.sslip.io';

  // Request Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout
  static const Duration timeoutDuration = Duration(seconds: 15);

  // Hive Settings Keys for Auth
  static const String accessTokenKey = 'api_access_token';
  static const String refreshTokenKey = 'api_refresh_token';
  static const String userDataKey = 'api_user_data';

  // ─── API Endpoints ──────────────────────────────────────────────

  // Health
  static const String health = '/v1/health';

  // Auth
  static const String login = '/v1/auth/login';
  static const String signup = '/v1/auth/signup';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String forgotPassword = '/v1/auth/forgot-password';
  static const String resetPassword = '/v1/auth/reset-password';
  static const String revokeAll = '/v1/auth/revoke-all';

  // Users
  static const String me = '/v1/users/me';
  static const String changePassword = '/v1/users/me/change-password';

  // Organizations
  static const String myOrganizations = '/v1/organizations/me';

  // Businesses
  static const String businesses = '/v1/businesses';
  static String businessDetail(String businessId) => '/v1/businesses/$businessId';

  // Workspaces
  static const String workspaces = '/v1/workspaces';
  static String workspaceDetail(String workspaceId) => '/v1/workspaces/$workspaceId';

  // Employees
  static String employees(String businessId) => '/v1/businesses/$businessId/employees';
  static String employeeDetail(String businessId, String employeeId) =>
      '/v1/businesses/$businessId/employees/$employeeId';

  // Projects
  static String projects(String businessId) => '/v1/businesses/$businessId/projects';
  static String projectDetail(String businessId, String projectId) =>
      '/v1/businesses/$businessId/projects/$projectId';

  // Tasks
  static String tasks(String businessId) => '/v1/businesses/$businessId/tasks';
  static String taskDetail(String businessId, String taskId) =>
      '/v1/businesses/$businessId/tasks/$taskId';

  // Notifications
  static const String notifications = '/v1/notifications';
  static String notificationMarkRead(String id) => '/v1/notifications/$id/read';
  static const String notificationsMarkAllRead = '/v1/notifications/read-all';
  static String notificationDetail(String id) => '/v1/notifications/$id';

  // Notes
  static String notes(String businessId) => '/v1/businesses/$businessId/notes';
  static String noteDetail(String businessId, String noteId) =>
      '/v1/businesses/$businessId/notes/$noteId';

  // Calendar
  static String calendarEvents(String businessId) => '/v1/businesses/$businessId/calendar-events';
  static String calendarEventDetail(String businessId, String eventId) =>
      '/v1/businesses/$businessId/calendar-events/$eventId';

  // Follow-ups
  static String followUps(String businessId) => '/v1/businesses/$businessId/follow-ups';
  static String followUpDetail(String businessId, String followUpId) =>
      '/v1/businesses/$businessId/follow-ups/$followUpId';

  // Finances
  static String financeSummary(String businessId) => '/v1/businesses/$businessId/finances/summary';
  static String incomeList(String businessId) => '/v1/businesses/$businessId/finances/income';
  static String incomeDetail(String businessId, String incomeId) =>
      '/v1/businesses/$businessId/finances/income/$incomeId';
  static String expenseList(String businessId) => '/v1/businesses/$businessId/finances/expenses';
  static String expenseDetail(String businessId, String expenseId) =>
      '/v1/businesses/$businessId/finances/expenses/$expenseId';

  // Jobs
  static String jobs(String businessId) => '/v1/businesses/$businessId/jobs';
  static String jobDetail(String businessId, String jobId) =>
      '/v1/businesses/$businessId/jobs/$jobId';

  // Payroll
  static String payrollList(String businessId) => '/v1/businesses/$businessId/payroll';
  static String payrollSummary(String businessId) => '/v1/businesses/$businessId/payroll/summary';
  static String payrollRun(String businessId) => '/v1/businesses/$businessId/payroll/run';
  static String payrollEntryDetail(String businessId, String entryId) =>
      '/v1/businesses/$businessId/payroll/$entryId';

  // Reports
  static const String reportsOverview = '/v1/reports/overview';
  static String businessReport(String businessId) => '/v1/businesses/$businessId/reports';
  static String financialTrend(String businessId) =>
      '/v1/businesses/$businessId/reports/financial-trend';
  static String projectAnalytics(String businessId) =>
      '/v1/businesses/$businessId/reports/project-analytics';

  // Storage
  static const String uploadFile = '/v1/storage/upload';
  static String getFile(String filename) => '/v1/storage/files/$filename';

  // Audit logs
  static String auditLogs(String businessId) => '/v1/businesses/$businessId/audit-logs';

  // Exports
  static String exportFinances(String businessId) => '/v1/businesses/$businessId/exports/finances';
  static String exportPayroll(String businessId) => '/v1/businesses/$businessId/exports/payroll';
  static String exportEmployees(String businessId) => '/v1/businesses/$businessId/exports/employees';
}
