// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_workflow.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkflowCategoryAdapter extends TypeAdapter<WorkflowCategory> {
  @override
  final int typeId = 11;

  @override
  WorkflowCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkflowCategory.productivity;
      case 1:
        return WorkflowCategory.focus;
      case 2:
        return WorkflowCategory.deadlines;
      case 3:
        return WorkflowCategory.notifications;
      case 4:
        return WorkflowCategory.organization;
      case 5:
        return WorkflowCategory.custom;
      default:
        return WorkflowCategory.productivity;
    }
  }

  @override
  void write(BinaryWriter writer, WorkflowCategory obj) {
    switch (obj) {
      case WorkflowCategory.productivity:
        writer.writeByte(0);
        break;
      case WorkflowCategory.focus:
        writer.writeByte(1);
        break;
      case WorkflowCategory.deadlines:
        writer.writeByte(2);
        break;
      case WorkflowCategory.notifications:
        writer.writeByte(3);
        break;
      case WorkflowCategory.organization:
        writer.writeByte(4);
        break;
      case WorkflowCategory.custom:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PresetWorkflowAdapter extends TypeAdapter<PresetWorkflow> {
  @override
  final int typeId = 12;

  @override
  PresetWorkflow read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PresetWorkflow(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as WorkflowCategory,
      rules: (fields[4] as List).cast<AutomationRule>(),
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      iconName: fields[7] as String?,
      tags: (fields[8] as List).cast<String>(),
      isBuiltIn: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PresetWorkflow obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.rules)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.iconName)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.isBuiltIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetWorkflowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}