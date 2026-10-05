import 'dart:io';

import 'package:bussiness_management/core/constants/app_constants.dart';
import 'package:bussiness_management/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('momentum_task_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(SubtaskModelAdapter());
    Hive.registerAdapter(CompatibleTaskModelAdapter());
    await Hive.openBox<TaskModel>(AppConstants.taskBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('persists task completion and subtasks without corrupting the box',
      () async {
    final completedAt = DateTime(2026, 1, 2, 3, 4);
    final task = TaskModel(
      id: 'task-1',
      workspaceId: 'workspace-1',
      title: 'Review launch plan',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
      isCompleted: true,
      completedAt: completedAt,
      subtasks: [
        SubtaskModel(id: 'subtask-1', title: 'Check logs', isCompleted: true),
      ],
    );

    final box = Hive.box<TaskModel>(AppConstants.taskBox);
    await box.put(task.id, task);

    final savedTask = box.get(task.id)!;
    expect(savedTask.completedAt, completedAt);
    expect(savedTask.subtasks, hasLength(1));
    expect(savedTask.subtasks.single.isCompleted, isTrue);
  });
}
