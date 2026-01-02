import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'automation_rule.dart';

part 'preset_workflow.g.dart';

/// Enum representing different workflow categories
@HiveType(typeId: 9)
enum WorkflowCategory {
  @HiveField(0)
  productivity,
  @HiveField(1)
  focus,
  @HiveField(2)
  deadlines,
  @HiveField(3)
  notifications,
  @HiveField(4)
  organization,
  @HiveField(5)
  custom,
}

/// Represents a preset workflow bundle containing multiple automation rules
@HiveType(typeId: 10)
class PresetWorkflow extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final WorkflowCategory category;
  
  @HiveField(4)
  final List<AutomationRule> rules;
  
  @HiveField(5)
  final bool isActive;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final String? iconName;
  
  @HiveField(8)
  final List<String> tags;
  
  @HiveField(9)
  final bool isBuiltIn;

  const PresetWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rules,
    required this.isActive,
    required this.createdAt,
    this.iconName,
    this.tags = const [],
    this.isBuiltIn = false,
  });

  /// Creates a new preset workflow
  factory PresetWorkflow.create({
    required String name,
    required String description,
    required WorkflowCategory category,
    required List<AutomationRule> rules,
    String? iconName,
    List<String> tags = const [],
    bool isBuiltIn = false,
  }) {
    return PresetWorkflow(
      id: _generateId(),
      name: name,
      description: description,
      category: category,
      rules: rules,
      isActive: true,
      createdAt: DateTime.now(),
      iconName: iconName,
      tags: tags,
      isBuiltIn: isBuiltIn,
    );
  }

  /// Creates a copy with updated fields
  PresetWorkflow copyWith({
    String? id,
    String? name,
    String? description,
    WorkflowCategory? category,
    List<AutomationRule>? rules,
    bool? isActive,
    DateTime? createdAt,
    String? iconName,
    List<String>? tags,
    bool? isBuiltIn,
  }) {
    return PresetWorkflow(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rules: rules ?? this.rules,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      iconName: iconName ?? this.iconName,
      tags: tags ?? this.tags,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  /// Activates the workflow
  PresetWorkflow activate() {
    return copyWith(isActive: true);
  }

  /// Deactivates the workflow
  PresetWorkflow deactivate() {
    return copyWith(isActive: false);
  }

  /// Gets the category display name
  String get categoryDisplayName {
    switch (category) {
      case WorkflowCategory.productivity:
        return 'Productivity';
      case WorkflowCategory.focus:
        return 'Focus';
      case WorkflowCategory.deadlines:
        return 'Deadlines';
      case WorkflowCategory.notifications:
        return 'Notifications';
      case WorkflowCategory.organization:
        return 'Organization';
      case WorkflowCategory.custom:
        return 'Custom';
    }
  }

  /// Gets the number of active rules in this workflow
  int get activeRulesCount => rules.where((rule) => rule.isActive).length;

  /// Gets a summary of what this workflow does
  String get summary {
    final ruleTypes = rules.map((rule) => rule.triggerDisplayName).toSet().toList();
    final actionTypes = rules
        .expand((rule) => rule.actions)
        .map((action) => action.typeDisplayName)
        .toSet()
        .toList();
    
    return 'Triggers on: ${ruleTypes.join(', ')}. Actions: ${actionTypes.join(', ')}.';
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'rules': rules.map((r) => r.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'iconName': iconName,
      'tags': tags,
      'isBuiltIn': isBuiltIn,
    };
  }

  /// Creates from JSON
  factory PresetWorkflow.fromJson(Map<String, dynamic> json) {
    return PresetWorkflow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: WorkflowCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => WorkflowCategory.custom,
      ),
      rules: (json['rules'] as List)
          .map((r) => AutomationRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      iconName: json['iconName'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        rules,
        isActive,
        createdAt,
        iconName,
        tags,
        isBuiltIn,
      ];

  @override
  String toString() {
    return 'PresetWorkflow(id: $id, name: $name, category: $category, rulesCount: ${rules.length}, isActive: $isActive)';
  }

  /// Generates a unique ID for new workflows
  static String _generateId() {
    return 'workflow_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  /// Built-in preset workflows for common use cases
  static List<PresetWorkflow> get builtInWorkflows => [
    // Focus Mode Workflow
    PresetWorkflow.create(
      name: 'Focus Mode',
      description: 'Automatically manages high-priority tasks and minimizes distractions by adding urgent tasks to focus mode and sending targeted notifications.',
      category: WorkflowCategory.focus,
      iconName: 'focus',
      tags: const ['productivity', 'focus', 'high-priority'],
      isBuiltIn: true,
      rules: [
        AutomationRule.create(
          name: 'Focus Mode - High Priority Tasks',
          trigger: RuleTrigger.taskCreated,
          conditions: [RuleCondition.priorityEquals('high')],
          actions: [
            RuleAction.addToFocusMode(),
            RuleAction.sendNotification(
              title: 'Focus Mode Activated',
              message: 'High priority task "{taskTitle}" added to focus mode',
            ),
          ],
          description: 'Automatically adds high priority tasks to focus mode',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Focus Mode - Urgent Deadlines',
          trigger: RuleTrigger.taskCreated,
          conditions: [
            RuleCondition.hasDeadline(),
            RuleCondition.deadlineWithin(24),
          ],
          actions: [
            RuleAction.addToFocusMode(),
            RuleAction.changePriority('high'),
            RuleAction.sendNotification(
              title: 'Urgent Task Detected',
              message: 'Task "{taskTitle}" has a deadline within 24 hours and has been prioritized',
            ),
          ],
          description: 'Prioritizes tasks with deadlines within 24 hours',
          isPreset: true,
        ),
      ],
    ),

    // Deadline Guard Workflow
    PresetWorkflow.create(
      name: 'Deadline Guard',
      description: 'Comprehensive deadline management system that provides multiple reminder stages and escalates priority as deadlines approach.',
      category: WorkflowCategory.deadlines,
      iconName: 'schedule',
      tags: const ['deadlines', 'reminders', 'time-management'],
      isBuiltIn: true,
      rules: [
        AutomationRule.create(
          name: 'Deadline Guard - 24 Hour Warning',
          trigger: RuleTrigger.deadlineApproaching,
          conditions: [
            RuleCondition.hasDeadline(),
            RuleCondition.deadlineWithin(24),
          ],
          actions: [
            RuleAction.sendNotification(
              title: 'Deadline Alert - 24 Hours',
              message: 'Task "{taskTitle}" is due in less than 24 hours: {deadline}',
            ),
            RuleAction.changePriority('high'),
            RuleAction.sendReminder(
              message: 'Reminder: "{taskTitle}" deadline approaching',
              delayMinutes: 360, // 6 hours later
            ),
          ],
          description: 'Sends alerts and reminders for tasks due within 24 hours',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Deadline Guard - Final Warning',
          trigger: RuleTrigger.deadlineApproaching,
          conditions: [
            RuleCondition.hasDeadline(),
            RuleCondition.deadlineWithin(2),
          ],
          actions: [
            RuleAction.sendNotification(
              title: 'URGENT: Deadline in 2 Hours',
              message: 'Task "{taskTitle}" is due very soon: {deadline}',
            ),
            RuleAction.addToFocusMode(),
            RuleAction.logActivity('Final deadline warning sent for urgent task'),
          ],
          description: 'Final urgent warning for tasks due within 2 hours',
          isPreset: true,
        ),
      ],
    ),

    // Productivity Booster Workflow
    PresetWorkflow.create(
      name: 'Productivity Booster',
      description: 'Enhances productivity by providing smart notifications, completion celebrations, and task organization features.',
      category: WorkflowCategory.productivity,
      iconName: 'trending_up',
      tags: const ['productivity', 'motivation', 'organization'],
      isBuiltIn: true,
      rules: [
        AutomationRule.create(
          name: 'Productivity Booster - New Task Welcome',
          trigger: RuleTrigger.taskCreated,
          conditions: const [], // No conditions - applies to all tasks
          actions: [
            RuleAction.sendNotification(
              title: 'Task Created Successfully',
              message: 'Your task "{taskTitle}" is ready to go! Priority: {priority}',
            ),
            RuleAction.logActivity('New task created and welcomed'),
          ],
          description: 'Welcomes new tasks with encouraging notifications',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Productivity Booster - Completion Celebration',
          trigger: RuleTrigger.taskCompleted,
          conditions: const [], // No conditions - applies to all completed tasks
          actions: [
            RuleAction.sendNotification(
              title: 'Great Job! 🎉',
              message: 'You completed "{taskTitle}"! Keep up the momentum!',
            ),
            RuleAction.logActivity('Task completion celebrated'),
          ],
          description: 'Celebrates task completions with motivational messages',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Productivity Booster - High Priority Motivation',
          trigger: RuleTrigger.taskCreated,
          conditions: [RuleCondition.priorityEquals('high')],
          actions: [
            RuleAction.sendNotification(
              title: 'High Priority Challenge',
              message: 'You\'ve got this! "{taskTitle}" is important - tackle it with confidence!',
            ),
            RuleAction.sendReminder(
              message: 'Don\'t forget your important task: "{taskTitle}"',
              delayMinutes: 120, // 2 hours later
            ),
          ],
          description: 'Provides motivation and reminders for high priority tasks',
          isPreset: true,
        ),
      ],
    ),

    // Smart Notifications Workflow
    PresetWorkflow.create(
      name: 'Smart Notifications',
      description: 'Intelligent notification system that adapts to task priority and context, reducing notification fatigue while keeping you informed.',
      category: WorkflowCategory.notifications,
      iconName: 'notifications_active',
      tags: const ['notifications', 'smart', 'adaptive'],
      isBuiltIn: true,
      rules: [
        AutomationRule.create(
          name: 'Smart Notifications - Priority-Based Timing',
          trigger: RuleTrigger.taskCreated,
          conditions: [RuleCondition.priorityEquals('medium')],
          actions: [
            RuleAction.sendReminder(
              message: 'Medium priority task reminder: "{taskTitle}"',
              delayMinutes: 240, // 4 hours for medium priority
            ),
          ],
          description: 'Sends delayed reminders based on task priority',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Smart Notifications - Context-Aware Deadlines',
          trigger: RuleTrigger.deadlineApproaching,
          conditions: [
            RuleCondition.hasDeadline(),
            RuleCondition.priorityEquals('low'),
          ],
          actions: [
            RuleAction.sendNotification(
              title: 'Gentle Reminder',
              message: 'Low priority task "{taskTitle}" has a deadline approaching: {deadline}',
            ),
          ],
          description: 'Gentle reminders for low priority tasks with deadlines',
          isPreset: true,
        ),
      ],
    ),

    // Task Organization Workflow
    PresetWorkflow.create(
      name: 'Task Organization',
      description: 'Automatically organizes and categorizes tasks based on content, priority, and deadlines to maintain a clean and structured task list.',
      category: WorkflowCategory.organization,
      iconName: 'folder_special',
      tags: const ['organization', 'categorization', 'structure'],
      isBuiltIn: true,
      rules: [
        AutomationRule.create(
          name: 'Task Organization - Meeting Tasks',
          trigger: RuleTrigger.taskCreated,
          conditions: [RuleCondition.titleContains('meeting')],
          actions: [
            RuleAction.changePriority('medium'),
            RuleAction.logActivity('Meeting task detected and prioritized'),
            RuleAction.sendNotification(
              title: 'Meeting Task Organized',
              message: 'Task "{taskTitle}" has been categorized as a meeting task',
            ),
          ],
          description: 'Automatically organizes tasks containing "meeting"',
          isPreset: true,
        ),
        AutomationRule.create(
          name: 'Task Organization - Urgent Keywords',
          trigger: RuleTrigger.taskCreated,
          conditions: [RuleCondition.titleContains('urgent')],
          actions: [
            RuleAction.changePriority('high'),
            RuleAction.addToFocusMode(),
            RuleAction.sendNotification(
              title: 'Urgent Task Auto-Prioritized',
              message: 'Task "{taskTitle}" has been marked as high priority due to urgent keywords',
            ),
          ],
          description: 'Auto-prioritizes tasks with urgent keywords',
          isPreset: true,
        ),
      ],
    ),
  ];
}