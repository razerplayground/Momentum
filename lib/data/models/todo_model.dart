import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 5)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  String priorityStr;

  @HiveField(7)
  String category;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  String? projectId;

  TodoModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    this.priorityStr = 'medium',
    this.category = 'General',
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.projectId,
  });

  factory TodoModel.create({
    required String workspaceId,
    required String title,
    String description = '',
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'General',
    String? projectId,
  }) {
    return TodoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueDate: dueDate,
      priorityStr: priority,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      projectId: projectId,
    );
  }
}
