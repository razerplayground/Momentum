import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/workspace_model.dart';
import '../services/api_service.dart';
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
  final apiService = ref.watch(apiServiceProvider);
  return WorkspaceNotifier(ref, apiService);
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
  final ApiService _apiService;

  WorkspaceNotifier(this._ref, this._apiService) : super([]) {
    loadWorkspaces();
  }

  /// Load workspaces from Hive box first, then fetch fresh list from REST API
  Future<void> loadWorkspaces() async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    final email = AuthService.getSessionEmail().trim().toLowerCase();
    final cached = box.values.toList();
    if (cached.isNotEmpty) {
      state = cached.where((w) => w.ownerEmail.isEmpty || w.ownerEmail == email).toList();
    }

    try {
      final remoteList = await _apiService.getWorkspaces();
      if (remoteList.isNotEmpty) {
        // Sync remote list into Hive box
        for (final ws in remoteList) {
          if (email.isNotEmpty && ws.ownerEmail.isEmpty) {
            ws.ownerEmail = email;
          }
          await box.put(ws.id, ws);
        }
        state = remoteList;

        // Ensure an active workspace ID is set if available
        final activeId = _ref.read(activeWorkspaceIdProvider);
        if ((activeId == null || !state.any((w) => w.id == activeId)) && state.isNotEmpty) {
          setActiveWorkspace(state.first.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to load remote workspaces, using local cache: $e');
    }
  }

  /// Add new workspace via REST API and save locally
  Future<bool> addWorkspace(WorkspaceModel workspace) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    final email = AuthService.getSessionEmail().trim().toLowerCase();
    workspace.ownerEmail = email;

    try {
      final created = await _apiService.createWorkspace(
        name: workspace.name,
        industry: workspace.industry,
        description: workspace.description,
        emoji: workspace.emoji,
        colorValue: workspace.colorValue,
      );
      created.ownerEmail = email;

      await box.put(created.id, created);
      state = [...state.where((w) => w.id != created.id), created];

      if (state.length == 1) {
        setActiveWorkspace(created.id);
      }
      return true;
    } catch (e) {
      debugPrint('API creation failed, saving locally: $e');
      await box.put(workspace.id, workspace);
      state = [...state, workspace];
      if (state.length == 1) {
        setActiveWorkspace(workspace.id);
      }
      return false;
    }
  }

  /// Update workspace details via REST API
  Future<bool> updateWorkspace(WorkspaceModel workspace) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);

    try {
      final updated = await _apiService.updateWorkspace(
        workspace.id,
        name: workspace.name,
        industry: workspace.industry,
        address: workspace.description,
      );

      final merged = updated.copyWith(
        emoji: workspace.emoji,
        colorValue: workspace.colorValue,
        description: workspace.description,
      );

      await box.put(merged.id, merged);
      state = state.map((w) => w.id == merged.id ? merged : w).toList();
      return true;
    } catch (e) {
      debugPrint('API update failed, updating locally: $e');
      await box.put(workspace.id, workspace);
      state = state.map((w) => w.id == workspace.id ? workspace : w).toList();
      return false;
    }
  }

  /// Delete workspace via REST API
  Future<void> deleteWorkspace(String id) async {
    final box = Hive.box<WorkspaceModel>(AppConstants.workspaceBox);
    try {
      await _apiService.deleteWorkspace(id);
    } catch (e) {
      debugPrint('API deletion failed: $e');
    }

    await box.delete(id);
    state = state.where((w) => w.id != id).toList();

    final activeId = _ref.read(activeWorkspaceIdProvider);
    if (activeId == id) {
      if (state.isNotEmpty) {
        setActiveWorkspace(state.first.id);
      } else {
        _ref.read(activeWorkspaceIdProvider.notifier).state = null;
      }
    }
  }

  /// Set active workspace ID
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
