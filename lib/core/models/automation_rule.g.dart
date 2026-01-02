// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RuleConditionAdapter extends TypeAdapter<RuleCondition> {
  @override
  final int typeId = 6;

  @override
  RuleCondition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RuleCondition(
      type: fields[0] as RuleConditionType,
      value: fields[1] as String,
      operator: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RuleCondition obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.operator);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleConditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleActionAdapter extends TypeAdapter<RuleAction> {
  @override
  final int typeId = 7;

  @override
  RuleAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RuleAction(
      type: fields[0] as RuleActionType,
      parameters: (fields[1] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RuleAction obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.parameters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AutomationRuleAdapter extends TypeAdapter<AutomationRule> {
  @override
  final int typeId = 8;

  @override
  AutomationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AutomationRule(
      id: fields[0] as String,
      name: fields[1] as String,
      trigger: fields[2] as RuleTrigger,
      conditions: (fields[3] as List).cast<RuleCondition>(),
      actions: (fields[4] as List).cast<RuleAction>(),
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      description: fields[7] as String?,
      isPreset: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AutomationRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.trigger)
      ..writeByte(3)
      ..write(obj.conditions)
      ..writeByte(4)
      ..write(obj.actions)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.isPreset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleTriggerAdapter extends TypeAdapter<RuleTrigger> {
  @override
  final int typeId = 3;

  @override
  RuleTrigger read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleTrigger.taskCreated;
      case 1:
        return RuleTrigger.deadlineApproaching;
      case 2:
        return RuleTrigger.taskCompleted;
      case 3:
        return RuleTrigger.taskDeleted;
      case 4:
        return RuleTrigger.highPriorityTask;
      case 5:
        return RuleTrigger.taskOverdue;
      case 6:
        return RuleTrigger.dailyReview;
      case 7:
        return RuleTrigger.weeklyReview;
      default:
        return RuleTrigger.taskCreated;
    }
  }

  @override
  void write(BinaryWriter writer, RuleTrigger obj) {
    switch (obj) {
      case RuleTrigger.taskCreated:
        writer.writeByte(0);
        break;
      case RuleTrigger.deadlineApproaching:
        writer.writeByte(1);
        break;
      case RuleTrigger.taskCompleted:
        writer.writeByte(2);
        break;
      case RuleTrigger.taskDeleted:
        writer.writeByte(3);
        break;
      case RuleTrigger.highPriorityTask:
        writer.writeByte(4);
        break;
      case RuleTrigger.taskOverdue:
        writer.writeByte(5);
        break;
      case RuleTrigger.dailyReview:
        writer.writeByte(6);
        break;
      case RuleTrigger.weeklyReview:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleTriggerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleConditionTypeAdapter extends TypeAdapter<RuleConditionType> {
  @override
  final int typeId = 4;

  @override
  RuleConditionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleConditionType.priorityEquals;
      case 1:
        return RuleConditionType.deadlineWithin;
      case 2:
        return RuleConditionType.titleContains;
      case 3:
        return RuleConditionType.reasonContains;
      case 4:
        return RuleConditionType.statusEquals;
      case 5:
        return RuleConditionType.createdWithin;
      case 6:
        return RuleConditionType.hasDeadline;
      case 7:
        return RuleConditionType.hasReason;
      default:
        return RuleConditionType.priorityEquals;
    }
  }

  @override
  void write(BinaryWriter writer, RuleConditionType obj) {
    switch (obj) {
      case RuleConditionType.priorityEquals:
        writer.writeByte(0);
        break;
      case RuleConditionType.deadlineWithin:
        writer.writeByte(1);
        break;
      case RuleConditionType.titleContains:
        writer.writeByte(2);
        break;
      case RuleConditionType.reasonContains:
        writer.writeByte(3);
        break;
      case RuleConditionType.statusEquals:
        writer.writeByte(4);
        break;
      case RuleConditionType.createdWithin:
        writer.writeByte(5);
        break;
      case RuleConditionType.hasDeadline:
        writer.writeByte(6);
        break;
      case RuleConditionType.hasReason:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleConditionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleActionTypeAdapter extends TypeAdapter<RuleActionType> {
  @override
  final int typeId = 5;

  @override
  RuleActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleActionType.sendNotification;
      case 1:
        return RuleActionType.sendReminder;
      case 2:
        return RuleActionType.changePriority;
      case 3:
        return RuleActionType.addToFocusMode;
      case 4:
        return RuleActionType.scheduleFollowUp;
      case 5:
        return RuleActionType.logActivity;
      case 6:
        return RuleActionType.sendEmail;
      case 7:
        return RuleActionType.createSubtask;
      default:
        return RuleActionType.sendNotification;
    }
  }

  @override
  void write(BinaryWriter writer, RuleActionType obj) {
    switch (obj) {
      case RuleActionType.sendNotification:
        writer.writeByte(0);
        break;
      case RuleActionType.sendReminder:
        writer.writeByte(1);
        break;
      case RuleActionType.changePriority:
        writer.writeByte(2);
        break;
      case RuleActionType.addToFocusMode:
        writer.writeByte(3);
        break;
      case RuleActionType.scheduleFollowUp:
        writer.writeByte(4);
        break;
      case RuleActionType.logActivity:
        writer.writeByte(5);
        break;
      case RuleActionType.sendEmail:
        writer.writeByte(6);
        break;
      case RuleActionType.createSubtask:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
