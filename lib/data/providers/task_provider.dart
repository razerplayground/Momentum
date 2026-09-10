import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final tasksProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  return TaskNotifier(ref);
});

final workspaceTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (activeId == null) return [];
  return tasks.where((t) => t.workspaceId == activeId).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final projectTasksProvider = Provider.family<List<TaskModel>, String>((ref, projectId) {
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
    final updated = TaskModel(
      id: task.id,
      workspaceId: task.workspaceId,
      projectId: task.projectId,
      title: task.title,
      description: task.description,
      statusStr: task.isCompleted ? 'todo' : 'done',
      priorityStr: task.priorityStr,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      assigneeIds: task.assigneeIds,
      tags: task.tags,
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
    );
    await updateTask(updated);
  }

  Future<void> deleteTask(String id) async {
    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    await box.delete(id);
    state = state.where((t) => t.id != id).toList();
  }
}
