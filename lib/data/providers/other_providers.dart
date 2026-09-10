import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment_model.dart';
import '../models/todo_model.dart';
import '../models/followup_model.dart';
import '../models/expense_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

// ─── Appointments ───────────────────────────────────────────────
final appointmentsProvider = StateNotifierProvider<AppointmentNotifier, List<AppointmentModel>>((ref) {
  return AppointmentNotifier(ref);
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Tracks which year/month is currently displayed in the calendar month-grid view.
/// Stored separately from selectedDateProvider so month navigation doesn't change the selected date.
final viewedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dayAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  if (activeId == null) return [];
  return appointments
      .where((a) =>
          a.workspaceId == activeId &&
          a.startTime.year == selectedDate.year &&
          a.startTime.month == selectedDate.month &&
          a.startTime.day == selectedDate.day)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Returns all appointments in the month currently shown in the month-grid view.
/// Used to render appointment-indicator dots on each day cell.
final monthAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final viewedMonth = ref.watch(viewedMonthProvider);
  if (activeId == null) return [];
  return appointments
      .where((a) =>
          a.workspaceId == activeId &&
          a.startTime.year == viewedMonth.year &&
          a.startTime.month == viewedMonth.month)
      .toList();
});

class AppointmentNotifier extends StateNotifier<List<AppointmentModel>> {
  final Ref _ref;
  AppointmentNotifier(this._ref) : super([]) { _load(); }

  void _load() {
    final box = Hive.box<AppointmentModel>(AppConstants.appointmentBox);
    state = box.values.toList();
  }

  Future<void> add(AppointmentModel a) async {
    final box = Hive.box<AppointmentModel>(AppConstants.appointmentBox);
    await box.put(a.id, a);
    state = [...state, a];
  }

  Future<void> delete(String id) async {
    final box = Hive.box<AppointmentModel>(AppConstants.appointmentBox);
    await box.delete(id);
    state = state.where((a) => a.id != id).toList();
  }

  Future<void> update(AppointmentModel a) async {
    final box = Hive.box<AppointmentModel>(AppConstants.appointmentBox);
    await box.put(a.id, a);
    state = state.map((x) => x.id == a.id ? a : x).toList();
  }
}

// ─── Todos ───────────────────────────────────────────────────────
final todosProvider = StateNotifierProvider<TodoNotifier, List<TodoModel>>((ref) {
  return TodoNotifier(ref);
});

final workspaceTodosProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todosProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (activeId == null) return [];
  return todos.where((t) => t.workspaceId == activeId).toList()
    ..sort((a, b) => a.isCompleted == b.isCompleted
        ? b.createdAt.compareTo(a.createdAt)
        : a.isCompleted ? 1 : -1);
});

class TodoNotifier extends StateNotifier<List<TodoModel>> {
  final Ref _ref;
  TodoNotifier(this._ref) : super([]) { _load(); }

  void _load() {
    final box = Hive.box<TodoModel>(AppConstants.todoBox);
    state = box.values.toList();
  }

  Future<void> add(TodoModel t) async {
    final box = Hive.box<TodoModel>(AppConstants.todoBox);
    await box.put(t.id, t);
    state = [...state, t];
  }

  Future<void> toggle(String id) async {
    final todo = state.firstWhere((t) => t.id == id);
    final updated = TodoModel(
      id: todo.id,
      workspaceId: todo.workspaceId,
      title: todo.title,
      description: todo.description,
      isCompleted: !todo.isCompleted,
      dueDate: todo.dueDate,
      priorityStr: todo.priorityStr,
      category: todo.category,
      createdAt: todo.createdAt,
      updatedAt: DateTime.now(),
      completedAt: todo.isCompleted ? null : DateTime.now(),
      projectId: todo.projectId,
    );
    final box = Hive.box<TodoModel>(AppConstants.todoBox);
    await box.put(updated.id, updated);
    state = state.map((t) => t.id == id ? updated : t).toList();
  }

  Future<void> delete(String id) async {
    final box = Hive.box<TodoModel>(AppConstants.todoBox);
    await box.delete(id);
    state = state.where((t) => t.id != id).toList();
  }
}

// ─── Follow-ups ──────────────────────────────────────────────────
final followupsProvider = StateNotifierProvider<FollowupNotifier, List<FollowupModel>>((ref) {
  return FollowupNotifier(ref);
});

final workspaceFollowupsProvider = Provider<List<FollowupModel>>((ref) {
  final items = ref.watch(followupsProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  if (activeId == null) return [];
  return items.where((f) => f.workspaceId == activeId).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

final projectFollowupsProvider = Provider.family<List<FollowupModel>, String>((ref, projectId) {
  final items = ref.watch(followupsProvider);
  return items.where((f) => f.projectId == projectId).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

class FollowupNotifier extends StateNotifier<List<FollowupModel>> {
  final Ref _ref;
  FollowupNotifier(this._ref) : super([]) { _load(); }

  void _load() {
    final box = Hive.box<FollowupModel>(AppConstants.followupBox);
    state = box.values.toList();
  }

  Future<void> add(FollowupModel f) async {
    final box = Hive.box<FollowupModel>(AppConstants.followupBox);
    await box.put(f.id, f);
    state = [...state, f];
  }

  Future<void> markDone(String id, String? response) async {
    final f = state.firstWhere((x) => x.id == id);
    final updated = FollowupModel(
      id: f.id,
      workspaceId: f.workspaceId,
      projectId: f.projectId,
      taskId: f.taskId,
      title: f.title,
      description: f.description,
      statusStr: 'done',
      typeStr: f.typeStr,
      dueDate: f.dueDate,
      createdAt: f.createdAt,
      updatedAt: DateTime.now(),
      assigneeIds: f.assigneeIds,
      response: response,
      completedAt: DateTime.now(),
    );
    final box = Hive.box<FollowupModel>(AppConstants.followupBox);
    await box.put(updated.id, updated);
    state = state.map((x) => x.id == id ? updated : x).toList();
  }

  Future<void> delete(String id) async {
    final box = Hive.box<FollowupModel>(AppConstants.followupBox);
    await box.delete(id);
    state = state.where((f) => f.id != id).toList();
  }
}

// ─── Expenses ────────────────────────────────────────────────────
final expensesProvider = StateNotifierProvider<ExpenseNotifier, List<ExpenseModel>>((ref) {
  return ExpenseNotifier(ref);
});

final projectExpensesProvider = Provider.family<List<ExpenseModel>, String>((ref, projectId) {
  final items = ref.watch(expensesProvider);
  return items.where((e) => e.projectId == projectId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

class ExpenseNotifier extends StateNotifier<List<ExpenseModel>> {
  final Ref _ref;
  ExpenseNotifier(this._ref) : super([]) { _load(); }

  void _load() {
    final box = Hive.box<ExpenseModel>(AppConstants.expenseBox);
    state = box.values.toList();
  }

  Future<void> add(ExpenseModel e) async {
    final box = Hive.box<ExpenseModel>(AppConstants.expenseBox);
    await box.put(e.id, e);
    state = [...state, e];
  }

  Future<void> delete(String id) async {
    final box = Hive.box<ExpenseModel>(AppConstants.expenseBox);
    await box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }
}
