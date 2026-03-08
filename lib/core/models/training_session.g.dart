// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingSessionAdapter extends TypeAdapter<TrainingSession> {
  @override
  final int typeId = 1;

  @override
  TrainingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSession(
      date: fields[0] as DateTime,
      type: fields[1] as TrainingType,
      durationSeconds: fields[2] as int,
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainingTypeAdapter extends TypeAdapter<TrainingType> {
  @override
  final int typeId = 0;

  @override
  TrainingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrainingType.nearFar;
      case 1:
        return TrainingType.tracking;
      case 2:
        return TrainingType.blurClarity;
      case 3:
        return TrainingType.convergence;
      case 4:
        return TrainingType.saccade;
      case 5:
        return TrainingType.contrastAdapt;
      case 6:
        return TrainingType.gaborPatch;
      default:
        return TrainingType.nearFar;
    }
  }

  @override
  void write(BinaryWriter writer, TrainingType obj) {
    switch (obj) {
      case TrainingType.nearFar:
        writer.writeByte(0);
        break;
      case TrainingType.tracking:
        writer.writeByte(1);
        break;
      case TrainingType.blurClarity:
        writer.writeByte(2);
        break;
      case TrainingType.convergence:
        writer.writeByte(3);
        break;
      case TrainingType.saccade:
        writer.writeByte(4);
        break;
      case TrainingType.contrastAdapt:
        writer.writeByte(5);
        break;
      case TrainingType.gaborPatch:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
