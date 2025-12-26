// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 9;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.automationApplied;
      case 1:
        return ActivityType.reminderSent;
      case 2:
        return ActivityType.notificationSent;
      case 3:
        return ActivityType.taskCreated;
      case 4:
        return ActivityType.taskCompleted;
      case 5:
        return ActivityType.taskDeleted;
      case 6:
        return ActivityType.taskRestored;
      case 7:
        return ActivityType.priorityChanged;
      case 8:
        return ActivityType.deadlineUpdated;
      case 9:
        return ActivityType.ruleCreated;
      case 10:
        return ActivityType.ruleActivated;
      case 11:
        return ActivityType.ruleDeactivated;
      case 12:
        return ActivityType.focusModeActivated;
      case 13:
        return ActivityType.cleanupPerformed;
      case 14:
        return ActivityType.errorOccurred;
      default:
        return ActivityType.automationApplied;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.automationApplied:
        writer.writeByte(0);
        break;
      case ActivityType.reminderSent:
        writer.writeByte(1);
        break;
      case ActivityType.notificationSent:
        writer.writeByte(2);
        break;
      case ActivityType.taskCreated:
        writer.writeByte(3);
        break;
      case ActivityType.taskCompleted:
        writer.writeByte(4);
        break;
      case ActivityType.taskDeleted:
        writer.writeByte(5);
        break;
      case ActivityType.taskRestored:
        writer.writeByte(6);
        break;
      case ActivityType.priorityChanged:
        writer.writeByte(7);
        break;
      case ActivityType.deadlineUpdated:
        writer.writeByte(8);
        break;
      case ActivityType.ruleCreated:
        writer.writeByte(9);
        break;
      case ActivityType.ruleActivated:
        writer.writeByte(10);
        break;
      case ActivityType.ruleDeactivated:
        writer.writeByte(11);
        break;
      case ActivityType.focusModeActivated:
        writer.writeByte(12);
        break;
      case ActivityType.cleanupPerformed:
        writer.writeByte(13);
        break;
      case ActivityType.errorOccurred:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 10;

  @override
  ActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLog(
      id: fields[0] as String,
      taskId: fields[1] as String?,
      ruleId: fields[2] as String?,
      type: fields[3] as ActivityType,
      description: fields[4] as String,
      metadata: Map<String, dynamic>.from(fields[5] as Map),
      timestamp: fields[6] as DateTime,
      userId: fields[7] as String?,
      isSystemGenerated: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.ruleId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.isSystemGenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}