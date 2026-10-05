import 'dart:io';

import 'package:bussiness_management/core/constants/app_constants.dart';
import 'package:bussiness_management/data/models/expense_model.dart';
import 'package:bussiness_management/data/models/followup_model.dart';
import 'package:bussiness_management/data/models/note_model.dart';
import 'package:bussiness_management/data/models/task_model.dart';
import 'package:bussiness_management/data/providers/project_progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('momentum_progress_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    await Hive.openBox<ExpenseModel>(AppConstants.expenseBox);
    await Hive.openBox<NoteModel>(AppConstants.noteBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('aggregates task, follow-up, finance, and note completion', () {
    final date = DateTime(2026, 1, 1);
    final progress = ProjectProgress.fromItems(
      tasks: [
        TaskModel(
          id: 'task-1',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Completed task',
          createdAt: date,
          updatedAt: date,
          isCompleted: true,
        ),
        TaskModel(
          id: 'task-2',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Legacy completed task',
          statusStr: 'done',
          createdAt: date,
          updatedAt: date,
        ),
      ],
      followups: [
        FollowupModel(
          id: 'followup-1',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Completed follow-up',
          statusStr: 'done',
          dueDate: date,
          createdAt: date,
          updatedAt: date,
        ),
        FollowupModel(
          id: 'followup-2',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Open follow-up',
          dueDate: date,
          createdAt: date,
          updatedAt: date,
        ),
      ],
      expenses: [
        ExpenseModel(
          id: 'expense-1',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Completed finance entry',
          amount: 20,
          date: date,
          createdAt: date,
          isCompleted: true,
        ),
      ],
      notes: [
        NoteModel(
          id: 'note-1',
          workspaceId: 'workspace-1',
          projectId: 'project-1',
          title: 'Open note',
          createdAt: date,
          updatedAt: date,
        ),
      ],
    );

    expect(progress.completed, 4);
    expect(progress.total, 6);
    expect(progress.value, closeTo(4 / 6, 0.0001));
  });

  test('empty project progress is zero', () {
    final progress = ProjectProgress.fromItems(
      tasks: [],
      followups: [],
      expenses: [],
      notes: [],
    );

    expect(progress.completed, 0);
    expect(progress.total, 0);
    expect(progress.value, 0);
  });

  test('persists manual finance and note completion', () async {
    final date = DateTime(2026, 1, 1);
    final expense = ExpenseModel(
      id: 'expense-1',
      workspaceId: 'workspace-1',
      projectId: 'project-1',
      title: 'Reviewed transaction',
      amount: 20,
      date: date,
      createdAt: date,
      isCompleted: true,
    );
    final note = NoteModel(
      id: 'note-1',
      workspaceId: 'workspace-1',
      projectId: 'project-1',
      title: 'Reviewed note',
      createdAt: date,
      updatedAt: date,
      isCompleted: true,
    );

    await Hive.box<ExpenseModel>(AppConstants.expenseBox)
        .put(expense.id, expense);
    await Hive.box<NoteModel>(AppConstants.noteBox).put(note.id, note);
    await Hive.close();
    await Hive.openBox<ExpenseModel>(AppConstants.expenseBox);
    await Hive.openBox<NoteModel>(AppConstants.noteBox);

    expect(
      Hive.box<ExpenseModel>(AppConstants.expenseBox)
          .get(expense.id)!
          .isCompleted,
      isTrue,
    );
    expect(
      Hive.box<NoteModel>(AppConstants.noteBox).get(note.id)!.isCompleted,
      isTrue,
    );
  });
}
