import 'package:hive/hive.dart';

part 'followup_model.g.dart';

enum FollowupStatus { pending, done, overdue, cancelled }
enum FollowupType { call, email, meeting, message, visit, other }

@HiveType(typeId: 7)
class FollowupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String? projectId;

  @HiveField(3)
  String? taskId;

  @HiveField(4)
  String title;

  @HiveField(5)
  String description;

  @HiveField(6)
  String statusStr;

  @HiveField(7)
  String typeStr;

  @HiveField(8)
  DateTime dueDate;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  List<String> assigneeIds;

  @HiveField(12)
  String? response; // notes after follow-up done

  @HiveField(13)
  DateTime? completedAt;

  FollowupModel({
    required this.id,
    required this.workspaceId,
    this.projectId,
    this.taskId,
    required this.title,
    this.description = '',
    this.statusStr = 'pending',
    this.typeStr = 'call',
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeIds = const [],
    this.response,
    this.completedAt,
  });

  FollowupStatus get status => FollowupStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => FollowupStatus.pending);

  FollowupType get type => FollowupType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FollowupType.other);

  factory FollowupModel.create({
    required String workspaceId,
    required String title,
    required DateTime dueDate,
    String? projectId,
    String? taskId,
    String description = '',
    String type = 'call',
    List<String> assigneeIds = const [],
  }) {
    return FollowupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      projectId: projectId,
      taskId: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      typeStr: type,
      assigneeIds: assigneeIds,
    );
  }
}
