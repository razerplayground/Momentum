class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'BizPro Manager';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String workspaceBox = 'workspaces';
  static const String projectBox = 'projects';
  static const String taskBox = 'tasks';
  static const String noteBox = 'notes';
  static const String appointmentBox = 'appointments';
  static const String todoBox = 'todos';
  static const String employeeBox = 'employees';
  static const String followupBox = 'followups';
  static const String expenseBox = 'expenses';
  static const String settingsBox = 'settings';

  // Hive Type IDs
  static const int workspaceTypeId = 0;
  static const int projectTypeId = 1;
  static const int taskTypeId = 2;
  static const int noteTypeId = 3;
  static const int appointmentTypeId = 4;
  static const int todoTypeId = 5;
  static const int employeeTypeId = 6;
  static const int followupTypeId = 7;
  static const int expenseTypeId = 8;
  static const int subtaskTypeId = 9;

  // Shared Prefs Keys
  static const String activeWorkspaceKey = 'active_workspace_id';
  static const String globalViewKey = 'global_view_enabled';
  static const String onboardingDoneKey = 'onboarding_done';

  // Pagination
  static const int pageSize = 20;

  // Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
