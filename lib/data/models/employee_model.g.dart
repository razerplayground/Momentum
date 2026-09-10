// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'employee_model.dart';

class EmployeeModelAdapter extends TypeAdapter<EmployeeModel> {
  @override
  final int typeId = 6;

  @override
  EmployeeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmployeeModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      name: fields[2] as String,
      email: fields[3] as String,
      phone: fields[4] as String,
      roleStr: fields[5] as String,
      statusStr: fields[6] as String,
      department: fields[7] as String,
      joinedAt: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
      avatarUrl: fields[10] as String?,
      salary: fields[11] as double,
      projectIds: (fields[12] as List).cast<String>(),
      notes: fields[13] as String?,
      avatarColorValue: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EmployeeModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.roleStr)
      ..writeByte(6)
      ..write(obj.statusStr)
      ..writeByte(7)
      ..write(obj.department)
      ..writeByte(8)
      ..write(obj.joinedAt)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.avatarUrl)
      ..writeByte(11)
      ..write(obj.salary)
      ..writeByte(12)
      ..write(obj.projectIds)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.avatarColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
