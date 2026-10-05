import 'package:hive/hive.dart';

part 'employee_model.g.dart';

enum EmployeeStatus { active, busy, inactive, onLeave }

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

  EmployeeStatus get status =>
      EmployeeStatus.values.firstWhere((e) => e.name == statusStr,
          orElse: () => EmployeeStatus.active);

  EmployeeRole get role => EmployeeRole.values
      .firstWhere((e) => e.name == roleStr, orElse: () => EmployeeRole.other);

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

  factory EmployeeModel.fromApiJson(
    Map<String, dynamic> json, {
    required String workspaceId,
  }) {
    final rawId = json['id'] ?? json['_id'];
    if (rawId == null) {
      throw const FormatException('Employee response is missing an id');
    }

    final rawUser = json['user'];
    final user =
        rawUser is Map<String, dynamic> ? rawUser : const <String, dynamic>{};
    final rawName = (json['name'] ?? user['name'])?.toString() ??
        '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final joinedAt =
        DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? createdAt;
    final rawProjects = json['projectIds'] ?? json['projects'];

    return EmployeeModel(
      id: rawId.toString(),
      workspaceId:
          (json['workspaceId'] ?? json['businessId'] ?? workspaceId).toString(),
      name: rawName.isEmpty ? 'Employee' : rawName,
      email: (json['email'] ?? user['email'])?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roleStr: (json['title'] ?? json['role'] ?? json['roleStr'] ?? 'other')
          .toString(),
      statusStr: (json['status'] ?? json['statusStr'] ?? 'active').toString(),
      department: json['department']?.toString() ?? 'General',
      joinedAt: joinedAt,
      createdAt: createdAt,
      avatarUrl: json['avatarUrl']?.toString(),
      salary: (json['salary'] as num?)?.toDouble() ?? 0,
      projectIds: rawProjects is List
          ? rawProjects.map((value) => value.toString()).toList()
          : const [],
      notes: json['notes']?.toString(),
      avatarColorValue: 0xFF7C3AED,
    );
  }

  Map<String, dynamic> toApiCreateJson() => {
        'name': name,
        'email': email,
        'title': roleStr,
        'status': statusStr,
        'department': department,
      };

  Map<String, dynamic> toApiUpdateJson() => {
        'title': roleStr,
        'status': statusStr,
        'department': department,
        'salary': salary,
      };
}
