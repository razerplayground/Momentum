// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'workspace_model.dart';

class WorkspaceModelAdapter extends TypeAdapter<WorkspaceModel> {
  @override
  final int typeId = 0;

  @override
  WorkspaceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkspaceModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      emoji: fields[3] as String,
      colorValue: fields[4] as int,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      industry: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkspaceModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.industry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
