import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final tasksProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  return TaskNotifier(ref);
});

final allTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final workspaceTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(allTasksProvider);
  final userWorkspaceIds = ref.watch(userWorkspaceIdsProvider);
  final isGlobalView = ref.watch(globalViewEnabledProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (isGlobalView) {
    return tasks
        .where((task) => userWorkspaceIds.contains(task.workspaceId))
        .toList();
  }
  if (activeId == null) return [];
  return tasks.where((t) => t.workspaceId == activeId).toList();
});

final projectTasksProvider =
    Provider.family<List<TaskModel>, String>((ref, projectId) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((t) => t.projectId == projectId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(workspaceTasksProvider);
  final today = DateTime.now();
  return tasks.where((t) {
    if (t.isCompleted || t.dueDate == null) return false;
    final due = t.dueDate!;
    return due.year == today.year &&
        due.month == today.month &&
        due.day == today.day;
  }).toList();
});

final overdueTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(workspaceTasksProvider);
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.isCompleted || t.dueDate == null) return false;
    return t.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }).toList();
});

// ─── Kanban grouping ─────────────────────────────────────────────
final tasksByStatusProvider =
    Provider<Map<TaskStatus, List<TaskModel>>>((ref) {
  final tasks = ref.watch(workspaceTasksProvider);
  final grouped = <TaskStatus, List<TaskModel>>{
    TaskStatus.todo: [],
    TaskStatus.inProgress: [],
    TaskStatus.review: [],
    TaskStatus.done: [],
  };
  for (final task in tasks) {
    grouped[task.status]!.add(task);
  }
  // Sort each column by priority (high first), then by updatedAt
  for (final list in grouped.values) {
    list.sort((a, b) {
      final priorityOrder = {
        'critical': 0,
        'high': 1,
        'medium': 2,
        'low': 3,
      };
      final pa = priorityOrder[a.priorityStr] ?? 2;
      final pb = priorityOrder[b.priorityStr] ?? 2;
      if (pa != pb) return pa.compareTo(pb);
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
  return grouped;
});

// ─── Single task lookup ──────────────────────────────────────────
final singleTaskProvider =
    Provider.family<TaskModel?, String>((ref, taskId) {
  final tasks = ref.watch(tasksProvider);
  final matches = tasks.where((t) => t.id == taskId);
  return matches.isEmpty ? null : matches.first;
});

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final Ref _ref;

  TaskNotifier(this._ref) : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    state = box.values.toList();
  }

  Future<void> addTask(TaskModel task) async {
    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    await box.put(task.id, task);
    state = [...state, task];
  }

  Future<void> updateTask(TaskModel task) async {
    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    await box.put(task.id, task);
    state = state.map((t) => t.id == task.id ? task : t).toList();
  }

  Future<void> toggleComplete(String id) async {
    final task = state.firstWhere((t) => t.id == id);
   
    final updated = task.copyWith(
      statusStr: task.isCompleted ? 'todo' : 'done',
      priorityStr: task.priorityStr,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      assigneeIds: task.assigneeIds,
      tags: task.tags,
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompletedAt: task.isCompleted,
    );
    await updateTask(updated);
    
  }

  Future<void> deleteTask(String id) async {
    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    await box.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  // ─── Status management (Kanban) ─────────────────────────────
  Future<void> updateTaskStatus(String id, String newStatus) async {
    final task = state.firstWhere((t) => t.id == id);
    final isDone = newStatus == 'done';
    final updated = task.copyWith(
      statusStr: newStatus,
      isCompleted: isDone,
      completedAt: isDone ? DateTime.now() : null,
      clearCompletedAt: !isDone,
    );
    await updateTask(updated);
  }

  // ─── Subtask CRUD ───────────────────────────────────────────
  Future<void> addSubtask(String taskId, SubtaskModel subtask) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedSubtasks = [...task.subtasks, subtask];
    final updated = task.copyWith(subtasks: updatedSubtasks);
    await updateTask(updated);
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();
    final updated = task.copyWith(subtasks: updatedSubtasks);
    await updateTask(updated);
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedSubtasks =
        task.subtasks.where((s) => s.id != subtaskId).toList();
    final updated = task.copyWith(subtasks: updatedSubtasks);
    await updateTask(updated);
  }

  Future<void> updateSubtaskTitle(
      String taskId, String subtaskId, String newTitle) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(title: newTitle);
      }
      return s;
    }).toList();
    final updated = task.copyWith(subtasks: updatedSubtasks);
    await updateTask(updated);
  }
}
