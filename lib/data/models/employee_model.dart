import 'package:hive/hive.dart';

part 'employee_model.g.dart';

enum EmployeeStatus { active, inactive, onLeave }
enum EmployeeRole { manager, developer, designer, sales, hr, accountant, other }

@HiveType(typeId: 6)
class EmployeeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String email;

  @HiveField(4)
  String phone;

  @HiveField(5)
  String roleStr;

  @HiveField(6)
  String statusStr;

  @HiveField(7)
  String department;

  @HiveField(8)
  DateTime joinedAt;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String? avatarUrl;

  @HiveField(11)
  double salary;

  @HiveField(12)
  List<String> projectIds;

  @HiveField(13)
  String? notes;

  @HiveField(14)
  int avatarColorValue;

  EmployeeModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.email = '',
    this.phone = '',
    this.roleStr = 'other',
    this.statusStr = 'active',
    this.department = 'General',
    required this.joinedAt,
    required this.createdAt,
    this.avatarUrl,
    this.salary = 0,
    this.projectIds = const [],
    this.notes,
    this.avatarColorValue = 0xFF7C3AED,
  });

  EmployeeStatus get status => EmployeeStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => EmployeeStatus.active);

  EmployeeRole get role => EmployeeRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => EmployeeRole.other);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory EmployeeModel.create({
    required String workspaceId,
    required String name,
    String email = '',
    String phone = '',
    String role = 'other',
    String department = 'General',
    double salary = 0,
    int avatarColorValue = 0xFF7C3AED,
  }) {
    return EmployeeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      name: name,
      email: email,
      phone: phone,
      roleStr: role,
      department: department,
      joinedAt: DateTime.now(),
      createdAt: DateTime.now(),
      salary: salary,
      avatarColorValue: avatarColorValue,
    );
  }
}
