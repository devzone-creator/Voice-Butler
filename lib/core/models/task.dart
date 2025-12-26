import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

/// Enum representing task priority levels
@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// Enum representing task status
@HiveType(typeId: 2)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  softDeleted,
}

/// Core Task model representing a discrete work item
@HiveType(typeId: 0)
class Task extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final TaskPriority priority;
  
  @HiveField(3)
  final String? reason;
  
  @HiveField(4)
  final DateTime? deadline;
  
  @HiveField(5)
  final TaskStatus status;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime? completedAt;
  
  @HiveField(8)
  final DateTime? deletedAt;
  
  @HiveField(9)
  final bool isDeleted;
  
  @HiveField(10)
  final bool recentDeleted;

  const Task({
    required this.id,
    required this.title,
    required this.priority,
    this.reason,
    this.deadline,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.recentDeleted = false,
  });

  /// Creates a new task with generated ID and current timestamp
  factory Task.create({
    required String title,
    required TaskPriority priority,
    String? reason,
    DateTime? deadline,
  }) {
    final now = DateTime.now();
    return Task(
      id: _generateId(),
      title: title,
      priority: priority,
      reason: reason,
      deadline: deadline,
      status: TaskStatus.pending,
      createdAt: now,
    );
  }

  /// Creates a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    String? reason,
    DateTime? deadline,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deletedAt,
    bool? isDeleted,
    bool? recentDeleted,
    bool clearDeletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      recentDeleted: recentDeleted ?? this.recentDeleted,
    );
  }

  /// Marks this task as completed
  Task markCompleted() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Marks this task as soft deleted
  Task markSoftDeleted() {
    final now = DateTime.now();
    return copyWith(
      status: TaskStatus.softDeleted,
      deletedAt: now,
      isDeleted: true,
      recentDeleted: true,
    );
  }

  /// Restores this task from soft deleted state
  Task restore() {
    return copyWith(
      status: TaskStatus.pending,
      isDeleted: false,
      recentDeleted: false,
      clearDeletedAt: true,
    );
  }

  /// Checks if this task should be automatically cleaned up (older than 7 days)
  bool shouldAutoCleanup() {
    if (!recentDeleted || deletedAt == null) return false;
    final daysSinceDeleted = DateTime.now().difference(deletedAt!).inDays;
    return daysSinceDeleted >= 7;
  }

  /// Checks if this task has a deadline approaching (within 24 hours)
  bool hasDeadlineApproaching() {
    if (deadline == null || status != TaskStatus.pending) return false;
    final hoursUntilDeadline = deadline!.difference(DateTime.now()).inHours;
    return hoursUntilDeadline <= 24 && hoursUntilDeadline > 0;
  }

  /// Checks if this task is overdue
  bool get isOverdue {
    if (deadline == null || status != TaskStatus.pending) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Gets the priority display name
  String get priorityDisplayName {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  /// Gets the status display name
  String get statusDisplayName {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.softDeleted:
        return 'Deleted';
    }
  }

  /// Converts task to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority.name,
      'reason': reason,
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'recentDeleted': recentDeleted,
    };
  }

  /// Creates task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      reason: json['reason'] as String?,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      recentDeleted: json['recentDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        priority,
        reason,
        deadline,
        status,
        createdAt,
        completedAt,
        deletedAt,
        isDeleted,
        recentDeleted,
      ];

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, status: $status)';
  }

  /// Generates a unique ID for new tasks
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
}