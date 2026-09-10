import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 3)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String? projectId;

  @HiveField(3)
  String title;

  @HiveField(4)
  String content;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String priorityStr; // high, medium, low, productive

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  List<String> sharedWithIds;

  @HiveField(10)
  bool isPinned;

  @HiveField(11)
  int colorValue;

  NoteModel({
    required this.id,
    required this.workspaceId,
    this.projectId,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.priorityStr = 'medium',
    required this.createdAt,
    required this.updatedAt,
    this.sharedWithIds = const [],
    this.isPinned = false,
    this.colorValue = 0xFFEDE9FE,
  });

  factory NoteModel.create({
    required String workspaceId,
    required String title,
    String content = '',
    String? projectId,
    List<String> tags = const [],
    String priority = 'medium',
    int colorValue = 0xFFEDE9FE,
  }) {
    return NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      projectId: projectId,
      title: title,
      content: content,
      tags: tags,
      priorityStr: priority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorValue: colorValue,
    );
  }
}
