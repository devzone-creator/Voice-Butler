import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'automation_rule.g.dart';

/// Enum representing different rule triggers
@HiveType(typeId: 3)
enum RuleTrigger {
  @HiveField(0)
  taskCreated,
  @HiveField(1)
  deadlineApproaching,
  @HiveField(2)
  taskCompleted,
  @HiveField(3)
  taskDeleted,
  @HiveField(4)
  highPriorityTask,
  @HiveField(5)
  taskOverdue,
  @HiveField(6)
  dailyReview,
  @HiveField(7)
  weeklyReview,
}

/// Enum representing different rule conditions
@HiveType(typeId: 4)
enum RuleConditionType {
  @HiveField(0)
  priorityEquals,
  @HiveField(1)
  deadlineWithin,
  @HiveField(2)
  titleContains,
  @HiveField(3)
  reasonContains,
  @HiveField(4)
  statusEquals,
  @HiveField(5)
  createdWithin,
  @HiveField(6)
  hasDeadline,
  @HiveField(7)
  hasReason,
}

/// Enum representing different rule actions
@HiveType(typeId: 5)
enum RuleActionType {
  @HiveField(0)
  sendNotification,
  @HiveField(1)
  sendReminder,
  @HiveField(2)
  changePriority,
  @HiveField(3)
  addToFocusMode,
  @HiveField(4)
  scheduleFollowUp,
  @HiveField(5)
  logActivity,
  @HiveField(6)
  sendEmail,
  @HiveField(7)
  createSubtask,
}

/// Represents a condition in an automation rule
@HiveType(typeId: 6)
class RuleCondition extends Equatable {
  @HiveField(0)
  final RuleConditionType type;
  
  @HiveField(1)
  final String value;
  
  @HiveField(2)
  final String? operator; // 'equals', 'contains', 'greater_than', 'less_than', etc.

  const RuleCondition({
    required this.type,
    required this.value,
    this.operator,
  });

  /// Creates a priority condition
  factory RuleCondition.priorityEquals(String priority) {
    return RuleCondition(
      type: RuleConditionType.priorityEquals,
      value: priority,
      operator: 'equals',
    );
  }

  /// Creates a deadline within condition
  factory RuleCondition.deadlineWithin(int hours) {
    return RuleCondition(
      type: RuleConditionType.deadlineWithin,
      value: hours.toString(),
      operator: 'less_than',
    );
  }

  /// Creates a title contains condition
  factory RuleCondition.titleContains(String text) {
    return RuleCondition(
      type: RuleConditionType.titleContains,
      value: text,
      operator: 'contains',
    );
  }

  /// Creates a has deadline condition
  factory RuleCondition.hasDeadline() {
    return const RuleCondition(
      type: RuleConditionType.hasDeadline,
      value: 'true',
      operator: 'equals',
    );
  }

  /// Gets display name for the condition type
  String get typeDisplayName {
    switch (type) {
      case RuleConditionType.priorityEquals:
        return 'Priority equals';
      case RuleConditionType.deadlineWithin:
        return 'Deadline within';
      case RuleConditionType.titleContains:
        return 'Title contains';
      case RuleConditionType.reasonContains:
        return 'Reason contains';
      case RuleConditionType.statusEquals:
        return 'Status equals';
      case RuleConditionType.createdWithin:
        return 'Created within';
      case RuleConditionType.hasDeadline:
        return 'Has deadline';
      case RuleConditionType.hasReason:
        return 'Has reason';
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      'operator': operator,
    };
  }

  /// Creates from JSON
  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    return RuleCondition(
      type: RuleConditionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RuleConditionType.priorityEquals,
      ),
      value: json['value'] as String,
      operator: json['operator'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, value, operator];
}

/// Represents an action in an automation rule
@HiveType(typeId: 7)
class RuleAction extends Equatable {
  @HiveField(0)
  final RuleActionType type;
  
  @HiveField(1)
  final Map<String, String> parameters;

  const RuleAction({
    required this.type,
    required this.parameters,
  });

  /// Creates a notification action
  factory RuleAction.sendNotification({
    required String title,
    required String message,
  }) {
    return RuleAction(
      type: RuleActionType.sendNotification,
      parameters: {
        'title': title,
        'message': message,
      },
    );
  }

  /// Creates a reminder action
  factory RuleAction.sendReminder({
    required String message,
    required int delayMinutes,
  }) {
    return RuleAction(
      type: RuleActionType.sendReminder,
      parameters: {
        'message': message,
        'delayMinutes': delayMinutes.toString(),
      },
    );
  }

  /// Creates a priority change action
  factory RuleAction.changePriority(String newPriority) {
    return RuleAction(
      type: RuleActionType.changePriority,
      parameters: {
        'priority': newPriority,
      },
    );
  }

  /// Creates a focus mode action
  factory RuleAction.addToFocusMode() {
    return const RuleAction(
      type: RuleActionType.addToFocusMode,
      parameters: {},
    );
  }

  /// Creates an activity log action
  factory RuleAction.logActivity(String message) {
    return RuleAction(
      type: RuleActionType.logActivity,
      parameters: {
        'message': message,
      },
    );
  }

  /// Gets display name for the action type
  String get typeDisplayName {
    switch (type) {
      case RuleActionType.sendNotification:
        return 'Send notification';
      case RuleActionType.sendReminder:
        return 'Send reminder';
      case RuleActionType.changePriority:
        return 'Change priority';
      case RuleActionType.addToFocusMode:
        return 'Add to focus mode';
      case RuleActionType.scheduleFollowUp:
        return 'Schedule follow-up';
      case RuleActionType.logActivity:
        return 'Log activity';
      case RuleActionType.sendEmail:
        return 'Send email';
      case RuleActionType.createSubtask:
        return 'Create subtask';
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }

  /// Creates from JSON
  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      type: RuleActionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RuleActionType.sendNotification,
      ),
      parameters: Map<String, String>.from(json['parameters'] as Map),
    );
  }

  @override
  List<Object?> get props => [type, parameters];
}

/// Represents an automation rule with trigger-condition-action pattern
@HiveType(typeId: 8)
class AutomationRule extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final RuleTrigger trigger;
  
  @HiveField(3)
  final List<RuleCondition> conditions;
  
  @HiveField(4)
  final List<RuleAction> actions;
  
  @HiveField(5)
  final bool isActive;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final String? description;
  
  @HiveField(8)
  final bool isPreset;

  const AutomationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.conditions,
    required this.actions,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.isPreset = false,
  });

  /// Creates a new automation rule
  factory AutomationRule.create({
    required String name,
    required RuleTrigger trigger,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
    String? description,
    bool isPreset = false,
  }) {
    return AutomationRule(
      id: _generateId(),
      name: name,
      trigger: trigger,
      conditions: conditions,
      actions: actions,
      isActive: true,
      createdAt: DateTime.now(),
      description: description,
      isPreset: isPreset,
    );
  }

  /// Creates a copy with updated fields
  AutomationRule copyWith({
    String? id,
    String? name,
    RuleTrigger? trigger,
    List<RuleCondition>? conditions,
    List<RuleAction>? actions,
    bool? isActive,
    DateTime? createdAt,
    String? description,
    bool? isPreset,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      trigger: trigger ?? this.trigger,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  /// Activates the rule
  AutomationRule activate() {
    return copyWith(isActive: true);
  }

  /// Deactivates the rule
  AutomationRule deactivate() {
    return copyWith(isActive: false);
  }

  /// Gets the trigger display name
  String get triggerDisplayName {
    switch (trigger) {
      case RuleTrigger.taskCreated:
        return 'Task created';
      case RuleTrigger.deadlineApproaching:
        return 'Deadline approaching';
      case RuleTrigger.taskCompleted:
        return 'Task completed';
      case RuleTrigger.taskDeleted:
        return 'Task deleted';
      case RuleTrigger.highPriorityTask:
        return 'High priority task';
      case RuleTrigger.taskOverdue:
        return 'Task overdue';
      case RuleTrigger.dailyReview:
        return 'Daily review';
      case RuleTrigger.weeklyReview:
        return 'Weekly review';
    }
  }

  /// Gets a human-readable description of the rule
  String get humanReadableDescription {
    final conditionsText = conditions.isEmpty 
        ? 'any task'
        : conditions.map((c) => '${c.typeDisplayName} ${c.value}').join(' and ');
    
    final actionsText = actions.map((a) => a.typeDisplayName).join(', ');
    
    return 'When $triggerDisplayName for $conditionsText, then $actionsText';
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'trigger': trigger.name,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'actions': actions.map((a) => a.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'isPreset': isPreset,
    };
  }

  /// Creates from JSON
  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      trigger: RuleTrigger.values.firstWhere(
        (t) => t.name == json['trigger'],
        orElse: () => RuleTrigger.taskCreated,
      ),
      conditions: (json['conditions'] as List)
          .map((c) => RuleCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List)
          .map((a) => RuleAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      isPreset: json['isPreset'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        trigger,
        conditions,
        actions,
        isActive,
        createdAt,
        description,
        isPreset,
      ];

  @override
  String toString() {
    return 'AutomationRule(id: $id, name: $name, trigger: $trigger, isActive: $isActive)';
  }

  /// Generates a unique ID for new rules
  static String _generateId() {
    return 'rule_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  /// Predefined automation rules for common use cases
  static List<AutomationRule> get presetRules => [
    // High priority task reminder
    AutomationRule.create(
      name: 'High Priority Reminder',
      trigger: RuleTrigger.taskCreated,
      conditions: [RuleCondition.priorityEquals('high')],
      actions: [
        RuleAction.sendNotification(
          title: 'High Priority Task Created',
          message: 'A high priority task needs your attention',
        ),
        RuleAction.sendReminder(message: 'Don\'t forget your high priority task', delayMinutes: 60),
      ],
      description: 'Sends immediate notification and 1-hour reminder for high priority tasks',
      isPreset: true,
    ),
    
    // Deadline approaching reminder
    AutomationRule.create(
      name: 'Deadline Guard',
      trigger: RuleTrigger.deadlineApproaching,
      conditions: [RuleCondition.hasDeadline()],
      actions: [
        RuleAction.sendNotification(
          title: 'Deadline Approaching',
          message: 'You have a task due soon',
        ),
        RuleAction.addToFocusMode(),
      ],
      description: 'Notifies when task deadlines are approaching and adds to focus mode',
      isPreset: true,
    ),
    
    // Focus mode for urgent tasks
    AutomationRule.create(
      name: 'Focus Mode',
      trigger: RuleTrigger.taskCreated,
      conditions: [
        RuleCondition.priorityEquals('high'),
        RuleCondition.deadlineWithin(24),
      ],
      actions: [
        RuleAction.addToFocusMode(),
        RuleAction.changePriority('high'),
      ],
      description: 'Automatically adds urgent tasks with near deadlines to focus mode',
      isPreset: true,
    ),
  ];
}