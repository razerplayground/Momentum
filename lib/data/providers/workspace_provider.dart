import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workspace_model.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/auth_service.dart';

final workspaceBoxProvider = Provider<Box<WorkspaceModel>>((ref) {
  return Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
});

final activeWorkspaceIdProvider = StateProvider.autoDispose<String?>((ref) {
  final box = Hive.box(AppConstants.settingsBox);
  return box.get(AuthService.userSettingKey(AppConstants.activeWorkspaceKey))
      as String?;
});

final globalViewEnabledProvider = StateProvider.autoDispose<bool>((ref) {
  final box = Hive.box(AppConstants.settingsBox);
  final enabled =
      box.get(AuthService.userSettingKey(AppConstants.globalViewKey));
  return enabled is bool ? enabled : false;
});

final workspacesProvider =
    StateNotifierProvider.autoDispose<WorkspaceNotifier, List<WorkspaceModel>>(
        (ref) {
  return WorkspaceNotifier(ref);
});

final userWorkspaceIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(workspacesProvider).map((workspace) => workspace.id).toSet();
});

final activeWorkspaceProvider = Provider<WorkspaceModel?>((ref) {
  final workspaces = ref.watch(workspacesProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final isGlobalView = ref.watch(globalViewEnabledProvider);

  if (isGlobalView) return null;
  if (workspaces.isEmpty) return null;
  if (activeId == null) return workspaces.first;

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
    final email = AuthService.getSessionEmail().trim().toLowerCase();
    final workspaces = box.values.toList();
    for (final workspace
        in workspaces.where((item) => item.ownerEmail.isEmpty)) {
      workspace.ownerEmail = email;
      box.put(workspace.id, workspace);
    }
    state =
        workspaces.where((workspace) => workspace.ownerEmail == email).toList();
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
    box.put(AuthService.userSettingKey(AppConstants.activeWorkspaceKey), id);
    box.put(AuthService.userSettingKey(AppConstants.globalViewKey), false);
    _ref.read(activeWorkspaceIdProvider.notifier).state = id;
    _ref.read(globalViewEnabledProvider.notifier).state = false;
  }

  void setGlobalView(bool enabled) {
    final box = Hive.box(AppConstants.settingsBox);
    box.put(AuthService.userSettingKey(AppConstants.globalViewKey), enabled);
    _ref.read(globalViewEnabledProvider.notifier).state = enabled;
  }
}
