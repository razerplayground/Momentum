import 'package:hive/hive.dart';

part 'task_model.g.dart';

enum TaskStatus { todo, inProgress, review, done }
enum TaskPriority { low, medium, high, critical }

@HiveType(typeId: 2)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String? projectId;

  @HiveField(3)
  String title;

  @HiveField(4)
  String description;

  @HiveField(5)
  String statusStr;

  @HiveField(6)
  String priorityStr;

  @HiveField(7)
  DateTime? dueDate;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  List<String> assigneeIds;

  @HiveField(11)
  List<String> tags;

  @HiveField(12)
  bool isCompleted;

  @HiveField(13)
  DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.workspaceId,
    this.projectId,
    required this.title,
    this.description = '',
    this.statusStr = 'todo',
    this.priorityStr = 'medium',
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeIds = const [],
    this.tags = const [],
    this.isCompleted = false,
    this.completedAt,
  });

  TaskStatus get status => TaskStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => TaskStatus.todo);

  TaskPriority get priority => TaskPriority.values.firstWhere(
      (e) => e.name == priorityStr,
      orElse: () => TaskPriority.medium);

  factory TaskModel.create({
    required String workspaceId,
    String? projectId,
    required String title,
    String description = '',
    String priority = 'medium',
    DateTime? dueDate,
    List<String> assigneeIds = const [],
    List<String> tags = const [],
  }) {
    return TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      projectId: projectId,
      title: title,
      description: description,
      priorityStr: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      assigneeIds: assigneeIds,
      tags: tags,
    );
  }
}
