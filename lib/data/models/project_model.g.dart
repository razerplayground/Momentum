// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'project_model.dart';

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 1;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String,
      statusStr: fields[4] as String,
      priorityStr: fields[5] as String,
      startDate: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      memberIds: (fields[10] as List).cast<String>(),
      budget: fields[11] as double,
      totalIncome: fields[12] as double,
      totalExpense: fields[13] as double,
      colorValue: fields[14] as int,
      emoji: fields[15] as String,
      completedTasks: fields[16] as int,
      totalTasks: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.statusStr)
      ..writeByte(5)
      ..write(obj.priorityStr)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.memberIds)
      ..writeByte(11)
      ..write(obj.budget)
      ..writeByte(12)
      ..write(obj.totalIncome)
      ..writeByte(13)
      ..write(obj.totalExpense)
      ..writeByte(14)
      ..write(obj.colorValue)
      ..writeByte(15)
      ..write(obj.emoji)
      ..writeByte(16)
      ..write(obj.completedTasks)
      ..writeByte(17)
      ..write(obj.totalTasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
