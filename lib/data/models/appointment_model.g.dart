// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'appointment_model.dart';

class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 4;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentModel(
      id: fields[0] as String,
      workspaceId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      startTime: fields[4] as DateTime,
      endTime: fields[5] as DateTime,
      location: fields[6] as String,
      attendeeIds: (fields[7] as List).cast<String>(),
      createdAt: fields[8] as DateTime,
      typeStr: fields[9] as String,
      colorValue: fields[10] as int,
      projectId: fields[11] as String?,
      isAllDay: fields[12] as bool,
      isCompleted: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workspaceId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.attendeeIds)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.typeStr)
      ..writeByte(10)
      ..write(obj.colorValue)
      ..writeByte(11)
      ..write(obj.projectId)
      ..writeByte(12)
      ..write(obj.isAllDay)
      ..writeByte(13)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
