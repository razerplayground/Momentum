import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/employee_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final employeesProvider =
    StateNotifierProvider<EmployeeNotifier, List<EmployeeModel>>((ref) {
  return EmployeeNotifier(ref);
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
  final Ref _ref;

  EmployeeNotifier(this._ref) : super([]) {
    _loadEmployees();
  }

  void _loadEmployees() {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    state = box.values.toList();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.put(employee.id, employee);
    state = [...state, employee];
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.put(employee.id, employee);
    state = state.map((e) => e.id == employee.id ? employee : e).toList();
  }

  Future<void> deleteEmployee(String id) async {
    final box = Hive.box<EmployeeModel>(AppConstants.employeeBox);
    await box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }
}
