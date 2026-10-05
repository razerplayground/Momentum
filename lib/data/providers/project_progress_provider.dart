import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_model.dart';
import '../models/followup_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import 'notes_provider.dart';
import 'other_providers.dart';
import 'task_provider.dart';

class ProjectProgress {
  final int completed;
  final int total;

  const ProjectProgress({required this.completed, required this.total});

  double get value => total == 0 ? 0 : completed / total;

  factory ProjectProgress.fromItems({
    required Iterable<TaskModel> tasks,
    required Iterable<FollowupModel> followups,
    required Iterable<ExpenseModel> expenses,
    required Iterable<NoteModel> notes,
  }) {
    final taskItems = tasks.toList();
    final followupItems = followups.toList();
    final expenseItems = expenses.toList();
    final noteItems = notes.toList();
    final completed = taskItems
            .where((task) => task.isCompleted || task.statusStr == 'done')
            .length +
        followupItems.where((followup) => followup.statusStr == 'done').length +
        expenseItems.where((expense) => expense.isCompleted).length +
        noteItems.where((note) => note.isCompleted).length;

    return ProjectProgress(
      completed: completed,
      total: taskItems.length +
          followupItems.length +
          expenseItems.length +
          noteItems.length,
    );
  }
}

final projectProgressProvider =
    Provider.family<ProjectProgress, String>((ref, projectId) {
  return ProjectProgress.fromItems(
    tasks: ref.watch(projectTasksProvider(projectId)),
    followups: ref.watch(projectFollowupsProvider(projectId)),
    expenses: ref.watch(projectExpensesProvider(projectId)),
    notes: ref.watch(notesProvider).where((note) => note.projectId == projectId),
  );
});
