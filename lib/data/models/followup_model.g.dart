// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'followup_model.dart';

class FollowupModelAdapter extends TypeAdapter<FollowupModel> {
  @override
  final int typeId = 7;

  @override
  FollowupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowupModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      projectId: fields[2] as String?,
      taskId: fields[3] as String?,
      title: fields[4] as String,
      description: fields[5] as String,
      statusStr: fields[6] as String,
      typeStr: fields[7] as String,
      dueDate: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      assigneeIds: (fields[11] as List).cast<String>(),
      response: fields[12] as String?,
      completedAt: fields[13] as DateTime?,
      
    );
  }

  @override
  void write(BinaryWriter writer, FollowupModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.projectId)
      ..writeByte(3)
      ..write(obj.taskId)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.statusStr)
      ..writeByte(7)
      ..write(obj.typeStr)
      ..writeByte(8)
      ..write(obj.dueDate)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.assigneeIds)
      ..writeByte(12)
      ..write(obj.response)
      ..writeByte(13)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
