import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

enum AppointmentType { meeting, call, visit, reminder, other }

@HiveType(typeId: 4)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  DateTime endTime;

  @HiveField(6)
  String location;

  @HiveField(7)
  List<String> attendeeIds;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String typeStr;

  @HiveField(10)
  int colorValue;

  @HiveField(11)
  String? projectId;

  @HiveField(12)
  bool isAllDay;

  @HiveField(13)
  bool isCompleted;

  AppointmentModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.attendeeIds = const [],
    required this.createdAt,
    this.typeStr = 'meeting',
    this.colorValue = 0xFF7C3AED,
    this.projectId,
    this.isAllDay = false,
    this.isCompleted = false,
  });

  AppointmentType get type => AppointmentType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AppointmentType.meeting);

  Duration get duration => endTime.difference(startTime);

  factory AppointmentModel.create({
    required String workspaceId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String description = '',
    String location = '',
    List<String> attendeeIds = const [],
    String type = 'meeting',
    int colorValue = 0xFF7C3AED,
    String? projectId,
  }) {
    return AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      attendeeIds: attendeeIds,
      createdAt: DateTime.now(),
      typeStr: type,
      colorValue: colorValue,
      projectId: projectId,
    );
  }
}
