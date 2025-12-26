import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'activity_log.g.dart';

/// Enum representing different types of activities
@HiveType(typeId: 9)
enum ActivityType {
  @HiveField(0)
  automationApplied,
  @HiveField(1)
  reminderSent,
  @HiveField(2)
  notificationSent,
  @HiveField(3)
  taskCreated,
  @HiveField(4)
  taskCompleted,
  @HiveField(5)
  taskDeleted,
  @HiveField(6)
  taskRestored,
  @HiveField(7)
  priorityChanged,
  @HiveField(8)
  deadlineUpdated,
  @HiveField(9)
  ruleCreated,
  @HiveField(10)
  ruleActivated,
  @HiveField(11)
  ruleDeactivated,
  @HiveField(12)
  focusModeActivated,
  @HiveField(13)
  cleanupPerformed,
  @HiveField(14)
  errorOccurred,
}

/// Represents a log entry for system activities and automation actions
@HiveType(typeId: 10)
class ActivityLog extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String? taskId;
  
  @HiveField(2)
  final String? ruleId;
  
  @HiveField(3)
  final ActivityType type;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final Map<String, dynamic> metadata;
  
  @HiveField(6)
  final DateTime timestamp;
  
  @HiveField(7)
  final String? userId;
  
  @HiveField(8)
  final bool isSystemGenerated;

  const ActivityLog({
    required this.id,
    this.taskId,
    this.ruleId,
    required this.type,
    required this.description,
    required this.metadata,
    required this.timestamp,
    this.userId,
    this.isSystemGenerated = true,
  });

  /// Creates a new activity log entry
  factory ActivityLog.create({
    String? taskId,
    String? ruleId,
    required ActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
    String? userId,
    bool isSystemGenerated = true,
  }) {
    return ActivityLog(
      id: _generateId(),
      taskId: taskId,
      ruleId: ruleId,
      type: type,
      description: description,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      userId: userId,
      isSystemGenerated: isSystemGenerated,
    );
  }

  /// Creates an automation applied log
  factory ActivityLog.automationApplied({
    required String taskId,
    required String ruleId,
    required String ruleName,
    required String action,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      ruleId: ruleId,
      type: ActivityType.automationApplied,
      description: 'Applied automation rule "$ruleName": $action',
      metadata: {
        'ruleName': ruleName,
        'action': action,
      },
    );
  }

  /// Creates a reminder sent log
  factory ActivityLog.reminderSent({
    required String taskId,
    required String taskTitle,
    required String reminderMessage,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      type: ActivityType.reminderSent,
      description: 'Sent reminder for task "$taskTitle"',
      metadata: {
        'taskTitle': taskTitle,
        'reminderMessage': reminderMessage,
      },
    );
  }

  /// Creates a notification sent log
  factory ActivityLog.notificationSent({
    required String taskId,
    required String taskTitle,
    required String notificationTitle,
    required String notificationMessage,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      type: ActivityType.notificationSent,
      description: 'Sent notification "$notificationTitle" for task "$taskTitle"',
      metadata: {
        'taskTitle': taskTitle,
        'notificationTitle': notificationTitle,
        'notificationMessage': notificationMessage,
      },
    );
  }

  /// Creates a task created log
  factory ActivityLog.taskCreated({
    required String taskId,
    required String taskTitle,
    required String priority,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      type: ActivityType.taskCreated,
      description: 'Created task "$taskTitle" with $priority priority',
      metadata: {
        'taskTitle': taskTitle,
        'priority': priority,
      },
      isSystemGenerated: false,
    );
  }

  /// Creates a task completed log
  factory ActivityLog.taskCompleted({
    required String taskId,
    required String taskTitle,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      type: ActivityType.taskCompleted,
      description: 'Completed task "$taskTitle"',
      metadata: {
        'taskTitle': taskTitle,
      },
      isSystemGenerated: false,
    );
  }

  /// Creates a task deleted log
  factory ActivityLog.taskDeleted({
    required String taskId,
    required String taskTitle,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      type: ActivityType.taskDeleted,
      description: 'Deleted task "$taskTitle"',
      metadata: {
        'taskTitle': taskTitle,
      },
      isSystemGenerated: false,
    );
  }

  /// Creates a rule created log
  factory ActivityLog.ruleCreated({
    required String ruleId,
    required String ruleName,
  }) {
    return ActivityLog.create(
      ruleId: ruleId,
      type: ActivityType.ruleCreated,
      description: 'Created automation rule "$ruleName"',
      metadata: {
        'ruleName': ruleName,
      },
      isSystemGenerated: false,
    );
  }

  /// Creates a cleanup performed log
  factory ActivityLog.cleanupPerformed({
    required int tasksCleanedCount,
  }) {
    return ActivityLog.create(
      type: ActivityType.cleanupPerformed,
      description: 'Performed automatic cleanup: removed $tasksCleanedCount old tasks',
      metadata: {
        'tasksCleanedCount': tasksCleanedCount.toString(),
      },
    );
  }

  /// Creates an error occurred log
  factory ActivityLog.errorOccurred({
    required String errorMessage,
    String? taskId,
    String? ruleId,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return ActivityLog.create(
      taskId: taskId,
      ruleId: ruleId,
      type: ActivityType.errorOccurred,
      description: 'Error occurred: $errorMessage',
      metadata: {
        'errorMessage': errorMessage,
        ...?additionalMetadata,
      },
    );
  }

  /// Creates a copy with updated fields
  ActivityLog copyWith({
    String? id,
    String? taskId,
    String? ruleId,
    ActivityType? type,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? userId,
    bool? isSystemGenerated,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      ruleId: ruleId ?? this.ruleId,
      type: type ?? this.type,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
    );
  }

  /// Gets the activity type display name
  String get typeDisplayName {
    switch (type) {
      case ActivityType.automationApplied:
        return 'Automation Applied';
      case ActivityType.reminderSent:
        return 'Reminder Sent';
      case ActivityType.notificationSent:
        return 'Notification Sent';
      case ActivityType.taskCreated:
        return 'Task Created';
      case ActivityType.taskCompleted:
        return 'Task Completed';
      case ActivityType.taskDeleted:
        return 'Task Deleted';
      case ActivityType.taskRestored:
        return 'Task Restored';
      case ActivityType.priorityChanged:
        return 'Priority Changed';
      case ActivityType.deadlineUpdated:
        return 'Deadline Updated';
      case ActivityType.ruleCreated:
        return 'Rule Created';
      case ActivityType.ruleActivated:
        return 'Rule Activated';
      case ActivityType.ruleDeactivated:
        return 'Rule Deactivated';
      case ActivityType.focusModeActivated:
        return 'Focus Mode Activated';
      case ActivityType.cleanupPerformed:
        return 'Cleanup Performed';
      case ActivityType.errorOccurred:
        return 'Error Occurred';
    }
  }

  /// Gets a formatted timestamp string
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Checks if this log entry is recent (within last hour)
  bool get isRecent {
    final difference = DateTime.now().difference(timestamp);
    return difference.inHours < 1;
  }

  /// Checks if this log entry is an error
  bool get isError {
    return type == ActivityType.errorOccurred;
  }

  /// Checks if this log entry is user-generated
  bool get isUserGenerated {
    return !isSystemGenerated;
  }

  /// Gets the icon name for this activity type
  String get iconName {
    switch (type) {
      case ActivityType.automationApplied:
        return 'auto_awesome';
      case ActivityType.reminderSent:
        return 'notifications';
      case ActivityType.notificationSent:
        return 'notification_important';
      case ActivityType.taskCreated:
        return 'add_task';
      case ActivityType.taskCompleted:
        return 'task_alt';
      case ActivityType.taskDeleted:
        return 'delete';
      case ActivityType.taskRestored:
        return 'restore';
      case ActivityType.priorityChanged:
        return 'priority_high';
      case ActivityType.deadlineUpdated:
        return 'schedule';
      case ActivityType.ruleCreated:
        return 'rule';
      case ActivityType.ruleActivated:
        return 'play_arrow';
      case ActivityType.ruleDeactivated:
        return 'pause';
      case ActivityType.focusModeActivated:
        return 'center_focus_strong';
      case ActivityType.cleanupPerformed:
        return 'cleaning_services';
      case ActivityType.errorOccurred:
        return 'error';
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'ruleId': ruleId,
      'type': type.name,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'isSystemGenerated': isSystemGenerated,
    };
  }

  /// Creates from JSON
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      ruleId: json['ruleId'] as String?,
      type: ActivityType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ActivityType.automationApplied,
      ),
      description: json['description'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      isSystemGenerated: json['isSystemGenerated'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        ruleId,
        type,
        description,
        metadata,
        timestamp,
        userId,
        isSystemGenerated,
      ];

  @override
  String toString() {
    return 'ActivityLog(id: $id, type: $type, description: $description, timestamp: $timestamp)';
  }

  /// Generates a unique ID for new activity logs
  static String _generateId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }
}