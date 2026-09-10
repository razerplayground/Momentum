import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workspace_model.dart';
import '../../core/constants/app_constants.dart';

final workspaceBoxProvider = Provider<Box<WorkspaceModel>>((ref) {
  return Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
});

final activeWorkspaceIdProvider = StateProvider<String?>((ref) {
  final box = Hive.box(AppConstants.settingsBox);
  return box.get(AppConstants.activeWorkspaceKey) as String?;
});

final workspacesProvider = StateNotifierProvider<WorkspaceNotifier, List<WorkspaceModel>>((ref) {
  return WorkspaceNotifier(ref);
});

final activeWorkspaceProvider = Provider<WorkspaceModel?>((ref) {
  final workspaces = ref.watch(workspacesProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (activeId == null || workspaces.isEmpty) return null;
  try {
    return workspaces.firstWhere((w) => w.id == activeId);
  } catch (_) {
    return workspaces.isNotEmpty ? workspaces.first : null;
  }
});

class WorkspaceNotifier extends StateNotifier<List<WorkspaceModel>> {
  final Ref _ref;

  WorkspaceNotifier(this._ref) : super([]) {
    _loadWorkspaces();
  }

  void _loadWorkspaces() {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    state = box.values.toList();
  }

  Future<void> addWorkspace(WorkspaceModel workspace) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    await box.put(workspace.id, workspace);
    state = [...state, workspace];

    // Set as active if first workspace
    if (state.length == 1) {
      setActiveWorkspace(workspace.id);
    }
  }

  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    await box.put(workspace.id, workspace);
    state = state.map((w) => w.id == workspace.id ? workspace : w).toList();
  }

  Future<void> deleteWorkspace(String id) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    await box.delete(id);
    state = state.where((w) => w.id != id).toList();
  }

  void setActiveWorkspace(String id) {
    final box = Hive.box(AppConstants.settingsBox);
    box.put(AppConstants.activeWorkspaceKey, id);
    _ref.read(activeWorkspaceIdProvider.notifier).state = id;
  }
}
