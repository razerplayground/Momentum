import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/employee_model.dart';
import '../models/workspace_model.dart';
import '../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final employeesProvider =
    StateNotifierProvider<EmployeeNotifier, List<EmployeeModel>>((ref) {
  final notifier = EmployeeNotifier(ref.watch(apiServiceProvider));
  ref.listen<List<WorkspaceModel>>(workspacesProvider, (_, workspaces) {
    notifier.loadRemoteEmployees(workspaces);
  });
  notifier.loadRemoteEmployees(ref.read(workspacesProvider));
  return notifier;
});

final workspaceEmployeesProvider = Provider<List<EmployeeModel>>((ref) {
  final employees = ref.watch(employeesProvider);
  final userWorkspaceIds = ref.watch(userWorkspaceIdsProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final isGlobalView = ref.watch(globalViewEnabledProvider);
  if (isGlobalView) {
    return employees
        .where((employee) => userWorkspaceIds.contains(employee.workspaceId))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  if (activeId == null) return [];
  return employees.where((e) => e.workspaceId == activeId).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

final activeEmployeesProvider = Provider<List<EmployeeModel>>((ref) {
  final employees = ref.watch(workspaceEmployeesProvider);
  return employees.where((e) => e.statusStr == 'active').toList();
});

class EmployeeNotifier extends StateNotifier<List<EmployeeModel>> {
  final ApiService _apiService;

  EmployeeNotifier(this._apiService) : super([]) {
    _loadEmployees();
  }

  void _loadEmployees() {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    state = box.values.toList();
  }

  Future<void> loadRemoteEmployees(List<WorkspaceModel> workspaces) async {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    for (final workspace in workspaces) {
      try {
        final results = await _apiService.getEmployees(workspace.id);
        final employees = results
            .map((json) => EmployeeModel.fromApiJson(
                  json,
                  workspaceId: workspace.id,
                ))
            .toList();
        final employeeIds = employees.map((employee) => employee.id).toSet();
        for (final employee in employees) {
          await box.put(employee.id, employee);
        }
        for (final cached in box.values
            .where((employee) => employee.workspaceId == workspace.id)
            .toList()) {
          if (!employeeIds.contains(cached.id)) {
            await box.delete(cached.id);
          }
        }
        state = [
          ...state.where((employee) => employee.workspaceId != workspace.id),
          ...employees,
        ];
      } catch (error) {
        debugPrint('Failed to load employees for ${workspace.id}: $error');
      }
    }
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final response = await _apiService.createEmployee(
      employee.workspaceId,
      employee.toApiCreateJson(),
    );
    final created = EmployeeModel.fromApiJson(
      response,
      workspaceId: employee.workspaceId,
    );
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.put(created.id, created);
    state = [...state.where((item) => item.id != created.id), created];
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await _apiService.updateEmployee(
      employee.workspaceId,
      employee.id,
      employee.toApiUpdateJson(),
    );
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.put(employee.id, employee);
    state = state.map((e) => e.id == employee.id ? employee : e).toList();
  }

  Future<void> deleteEmployee(String id) async {
    final employee = state.firstWhere((employee) => employee.id == id);
    await _apiService.deleteEmployee(employee.workspaceId, employee.id);
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }
}
