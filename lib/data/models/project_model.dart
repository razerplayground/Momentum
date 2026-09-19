import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project_model.g.dart';

enum ProjectStatus { active, paused, completed, cancelled }

enum ProjectPriority { low, medium, high, critical }

@HiveType(typeId: 1)
class ProjectModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String description;

  @HiveField(4)
  String statusStr;

  @HiveField(5)
  String priorityStr;

  @HiveField(6)
  DateTime startDate;

  @HiveField(7)
  DateTime? dueDate;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  List<String> memberIds;

  @HiveField(11)
  double budget;

  @HiveField(12)
  double totalIncome;

  @HiveField(13)
  double totalExpense;

  @HiveField(14)
  int colorValue;

  @HiveField(15)
  String emoji;

  @HiveField(16)
  int completedTasks;

  @HiveField(17)
  int totalTasks;

  ProjectModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description = '',
    this.statusStr = 'active',
    this.priorityStr = 'medium',
    required this.startDate,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.memberIds = const [],
    this.budget = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.colorValue = 0xFF7C3AED,
    this.emoji = '📁',
    this.completedTasks = 0,
    this.totalTasks = 0,
  });

  ProjectStatus get status =>
      ProjectStatus.values.firstWhere((e) => e.name == statusStr,
          orElse: () => ProjectStatus.active);

  ProjectPriority get priority =>
      ProjectPriority.values.firstWhere((e) => e.name == priorityStr,
          orElse: () => ProjectPriority.medium);

  double get progress =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks).clamp(0.0, 1.0);

  double get profit => totalIncome - totalExpense;

  factory ProjectModel.create({
    required String workspaceId,
    required String name,
    String description = '',
    String priority = 'medium',
    DateTime? dueDate,
    int colorValue = 0xFF7C3AED,
    String emoji = '📁',
    double budget = 0,
  }) {
    return ProjectModel(
      id: Uuid().v4(),
      workspaceId: workspaceId,
      name: name,
      description: description,
      priorityStr: priority,
      startDate: DateTime.now(),
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorValue: colorValue,
      emoji: emoji,
      budget: budget,
    );
  }
}
