import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final projectsProvider =
    StateNotifierProvider<ProjectNotifier, List<ProjectModel>>((ref) {
  return ProjectNotifier(ref);
});

final allProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectsProvider);
  return projects.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final workspaceProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(allProjectsProvider);
  final userWorkspaceIds = ref.watch(userWorkspaceIdsProvider);
  final isGlobalView = ref.watch(globalViewEnabledProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (isGlobalView) {
    return projects
        .where((project) => userWorkspaceIds.contains(project.workspaceId))
        .toList();
  }
  if (activeId == null) return [];
  return projects.where((p) => p.workspaceId == activeId).toList();
});

final projectByIdProvider = Provider.family<ProjectModel?, String>((ref, id) {
  final projects = ref.watch(projectsProvider);
  try {
    return projects.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

class ProjectNotifier extends StateNotifier<List<ProjectModel>> {
  final Ref _ref;

  ProjectNotifier(this._ref) : super([]) {
    _loadProjects();
  }

  void _loadProjects() {
    final box = Hive.box<ProjectModel>(AppConstants.projectBox);
    state = box.values.toList();
  }

  Future<void> addProject(ProjectModel project) async {
    final box = Hive.box<ProjectModel>(AppConstants.projectBox);
    await box.put(project.id, project);
    state = [...state, project];
  }

  Future<void> updateProject(ProjectModel project) async {
    final box = Hive.box<ProjectModel>(AppConstants.projectBox);
    await box.put(project.id, project);
    state = state.map((p) => p.id == project.id ? project : p).toList();
  }

  Future<void> deleteProject(String id) async {
    final box = Hive.box<ProjectModel>(AppConstants.projectBox);
    await box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> updateFinancials(String projectId) async {
    final expenseBox = Hive.box<dynamic>(AppConstants.expenseBox);
    final expenses =
        expenseBox.values.where((e) => e.projectId == projectId).toList();

    double income = 0, expense = 0;
    for (final e in expenses) {
      if (e.typeStr == 'income') {
        income += e.amount as double;
      } else {
        expense += e.amount as double;
      }
    }

    final project = state.firstWhere((p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'));
    project.totalIncome = income;
    project.totalExpense = expense;
    await updateProject(project);
  }
}
