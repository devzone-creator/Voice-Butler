import 'package:flutter/foundation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/automation_rule.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/task.dart';

class AutomationProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  
  List<AutomationRule> _rules = [];
  bool _isInitialized = false;

  List<AutomationRule> get rules => _rules;
  List<AutomationRule> get activeRules => _rules.where((r) => r.isActive).toList();
  bool get isInitialized => _isInitialized;

  AutomationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadRules();
      await _createDefaultRules();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Failed to initialize automation: $e');
    }
  }

  Future<void> _loadRules() async {
    _rules = _storageService.getAllAutomationRules();
  }

  Future<void> _createDefaultRules() async {
    if (_rules.isEmpty) {
      // Create default deadline reminder rule
      final deadlineRule = AutomationRule.create(
        name: 'Deadline Reminders',
        trigger: RuleTrigger.deadlineApproaching,
        conditions: [RuleCondition.hasDeadline()],
        actions: [RuleAction.sendNotification(
          title: 'Deadline Approaching',
          message: 'Task deadline is within 24 hours',
        )],
        description: 'Send notifications for approaching deadlines',
      );

      // Create high priority rule
      final priorityRule = AutomationRule.create(
        name: 'High Priority Alerts',
        trigger: RuleTrigger.taskCreated,
        conditions: [RuleCondition.priorityEquals('high')],
        actions: [RuleAction.sendNotification(
          title: 'High Priority Task',
          message: 'New high priority task created',
        )],
        description: 'Alert for high priority tasks',
      );

      await addRule(deadlineRule);
      await addRule(priorityRule);
    }
  }

  Future<void> addRule(AutomationRule rule) async {
    await _storageService.storeAutomationRule(rule);
    _rules.add(rule);
    notifyListeners();
  }

  Future<void> updateRule(AutomationRule rule) async {
    await _storageService.storeAutomationRule(rule);
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
      notifyListeners();
    }
  }

  Future<void> deleteRule(String ruleId) async {
    await _storageService.deleteAutomationRule(ruleId);
    _rules.removeWhere((r) => r.id == ruleId);
    notifyListeners();
  }

  Future<void> applyAutomationRules(Task task) async {
    for (final rule in activeRules) {
      if (_shouldTriggerRule(rule, task)) {
        await _executeRule(rule, task);
      }
    }
  }

  bool _shouldTriggerRule(AutomationRule rule, Task task) {
    // Check trigger
    switch (rule.trigger) {
      case RuleTrigger.taskCreated:
        // Always trigger for new tasks
        break;
      case RuleTrigger.deadlineApproaching:
        if (!task.hasDeadlineApproaching()) return false;
        break;
      case RuleTrigger.taskCompleted:
        if (task.status != TaskStatus.completed) return false;
        break;
      case RuleTrigger.taskDeleted:
        if (task.status != TaskStatus.softDeleted) return false;
        break;
      default:
        // Handle any other trigger types
        break;
      // case RuleTrigger.priorityChanged:
      //   // Would need to track previous state
      //   break;
    }

    // Check conditions
    for (final condition in rule.conditions) {
      if (!_evaluateCondition(condition, task)) {
        return false;
      }
    }

    return true;
  }

  bool _evaluateCondition(RuleCondition condition, Task task) {
    switch (condition.type) {
      case RuleConditionType.priorityEquals:
        final priority = TaskPriority.values.firstWhere(
          (p) => p.name == condition.value,
          orElse: () => TaskPriority.medium,
        );
        return task.priority == priority;
      case RuleConditionType.hasDeadline:
        return task.deadline != null;
      case RuleConditionType.titleContains:
        return task.title.toLowerCase().contains(condition.value.toLowerCase());
      case RuleConditionType.deadlineWithin:
        if (task.deadline == null) return false;
        final days = int.tryParse(condition.value) ?? 1;
        return task.deadline!.difference(DateTime.now()).inDays <= days;
      default:
        return false;
      // case RuleConditionType.isOverdue:
      //   return task.isOverdue;
    }
  }

  Future<void> _executeRule(AutomationRule rule, Task task) async {
    try {
      for (final action in rule.actions) {
        await _executeAction(action, task, rule);
      }

      // Log the automation execution
      final log = ActivityLog.create(
        taskId: task.id,
        type: ActivityType.automationApplied,
        description: 'Applied rule: ${rule.name}',
        metadata: {
          'ruleId': rule.id,
          'ruleName': rule.name,
          'actionsCount': rule.actions.length,
        },
      );
      await _storageService.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) print('Failed to execute rule ${rule.name}: $e');
    }
  }

  Future<void> _executeAction(RuleAction action, Task task, AutomationRule rule) async {
    switch (action.type) {
      case RuleActionType.sendNotification:
        try {
          await NotificationService.instance.showTaskReminder(
            id: task.id.hashCode,
            title: action.parameters['title'] ?? 'Task Reminder',
            body: action.parameters['message'] ?? 'You have a task reminder',
          );
          
          // Log notification sent
          final notificationLog = ActivityLog.create(
            taskId: task.id,
            type: ActivityType.notificationSent,
            description: 'Notification sent: ${action.parameters['title']}',
            metadata: {
              'ruleId': rule.id,
              'ruleName': rule.name,
              'notificationTitle': action.parameters['title'],
              'notificationMessage': action.parameters['message'],
            },
          );
          await _storageService.storeActivityLog(notificationLog);
          
          if (kDebugMode) {
            print('Notification sent: ${action.parameters['title']} - ${action.parameters['message']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to send notification: $e');
          }
          
          // Log notification failure
          final errorLog = ActivityLog.errorOccurred(
            errorMessage: 'Failed to send notification: $e',
            additionalMetadata: {
              'ruleId': rule.id,
              'taskId': task.id,
            },
          );
          await _storageService.storeActivityLog(errorLog);
        }
        break;
        
      case RuleActionType.sendReminder:
        try {
          await NotificationService.instance.showTaskReminder(
            id: task.id.hashCode + 1000, // Different ID for reminders
            title: 'Task Reminder',
            body: action.parameters['message'] ?? 'Don\'t forget about your task: ${task.title}',
          );
          
          // Log reminder sent
          final reminderLog = ActivityLog.create(
            taskId: task.id,
            type: ActivityType.reminderSent,
            description: 'Reminder sent for task: ${task.title}',
            metadata: {
              'ruleId': rule.id,
              'ruleName': rule.name,
              'reminderMessage': action.parameters['message'],
            },
          );
          await _storageService.storeActivityLog(reminderLog);
          
          if (kDebugMode) {
            print('Reminder sent: ${action.parameters['message']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to send reminder: $e');
          }
          
          // Log reminder failure
          final errorLog = ActivityLog.errorOccurred(
            errorMessage: 'Failed to send reminder: $e',
            additionalMetadata: {
              'ruleId': rule.id,
              'taskId': task.id,
            },
          );
          await _storageService.storeActivityLog(errorLog);
        }
        break;
        
      default:
        // Handle any other action types
        if (kDebugMode) {
          print('Unknown action type: ${action.type}');
        }
        break;
    }
  }
}