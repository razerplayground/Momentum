import 'package:hive/hive.dart';

part 'task_model.g.dart';

enum TaskStatus { todo, inProgress, review, done }

enum TaskPriority { low, medium, high, critical }

@HiveType(typeId: 9)
class SubtaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  SubtaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory SubtaskModel.create({required String title}) {
    return SubtaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
  }

  SubtaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

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

  @HiveField(14, defaultValue: [])
  List<SubtaskModel> subtasks;

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
    this.subtasks = const [],
  });

  TaskStatus get status => TaskStatus.values
      .firstWhere((e) => e.name == statusStr, orElse: () => TaskStatus.todo);

  TaskPriority get priority =>
      TaskPriority.values.firstWhere((e) => e.name == priorityStr,
          orElse: () => TaskPriority.medium);

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  double get subtaskProgress =>
      subtasks.isEmpty ? 0.0 : completedSubtaskCount / subtasks.length;

  factory TaskModel.create({
    required String workspaceId,
    String? projectId,
    required String title,
    String description = '',
    String status = 'todo',
    String priority = 'medium',
    DateTime? dueDate,
    List<String> assigneeIds = const [],
    List<String> tags = const [],
    List<SubtaskModel> subtasks = const [],
  }) {
    return TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      projectId: projectId,
      title: title,
      description: description,
      statusStr: status,
      priorityStr: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      assigneeIds: assigneeIds,
      tags: tags,
      subtasks: subtasks,
    );
  }

  TaskModel copyWith({
    String? id,
    String? workspaceId,
    String? projectId,
    String? title,
    String? description,
    String? statusStr,
    String? priorityStr,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? assigneeIds,
    List<String>? tags,
    bool? isCompleted,
    DateTime? completedAt,
    List<SubtaskModel>? subtasks,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
    bool clearProjectId = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      title: title ?? this.title,
      description: description ?? this.description,
      statusStr: statusStr ?? this.statusStr,
      priorityStr: priorityStr ?? this.priorityStr,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      assigneeIds: assigneeIds ?? List.from(this.assigneeIds),
      tags: tags ?? List.from(this.tags),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      subtasks: subtasks ?? List.from(this.subtasks),
    );
  }
}

class CompatibleTaskModelAdapter extends TaskModelAdapter {
  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final firstFieldId = reader.readByte();
    final fields = <int, dynamic>{};

    if (firstFieldId == 15) {
      // Previous generated code emitted an extra field ID and completion date.
      var fieldId = reader.readByte();
      for (var i = 0; i < numOfFields; i++) {
        fields[fieldId] = reader.read();
        if (i < numOfFields - 1) fieldId = reader.readByte();
      }

      reader.read();
      final trailingFieldId = reader.readByte();
      if (trailingFieldId == 14) fields[14] = reader.read();
    } else {
      fields[firstFieldId] = reader.read();
      for (var i = 1; i < numOfFields; i++) {
        fields[reader.readByte()] = reader.read();
      }
    }

    return TaskModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      projectId: fields[2] as String?,
      title: fields[3] as String,
      description: fields[4] as String,
      statusStr: fields[5] as String,
      priorityStr: fields[6] as String,
      dueDate: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      assigneeIds: (fields[10] as List).cast<String>(),
      tags: (fields[11] as List).cast<String>(),
      isCompleted: fields[12] as bool,
      completedAt: fields[13] as DateTime?,
      subtasks: (fields[14] as List?)?.cast<SubtaskModel>() ?? const [],
    );
  }
}
