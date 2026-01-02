import 'package:flutter/foundation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/models/automation_rule.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/task.dart';

class AutomationProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final BackgroundService _backgroundService = BackgroundService.instance;
  
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
    // Temporarily disabled for demo
    if (kDebugMode) {
      print('Automation rules disabled for demo - task created: ${task.title}');
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
      // Create detailed explanation of why the rule was triggered
      final triggerExplanation = _createTriggerExplanation(rule, task);
      
      for (final action in rule.actions) {
        await _executeAction(action, task, rule);
      }

      // Log the automation execution with detailed explanation
      final log = ActivityLog.create(
        taskId: task.id,
        type: ActivityType.automationApplied,
        description: 'Applied automation rule "${rule.name}": $triggerExplanation',
        metadata: {
          'ruleId': rule.id,
          'ruleName': rule.name,
          'actionsCount': rule.actions.length,
          'triggerType': rule.trigger.name,
          'triggerExplanation': triggerExplanation,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
          'conditionsCount': rule.conditions.length,
        },
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Executed rule "${rule.name}" for task "${task.title}": $triggerExplanation');
      }
    } catch (e) {
      // Handle rule execution failures gracefully
      await _handleRuleExecutionFailure(e, rule, task);
    }
  }

  /// Creates a detailed explanation of why an automation rule was triggered
  String _createTriggerExplanation(AutomationRule rule, Task task) {
    final buffer = StringBuffer();
    
    // Explain the trigger
    switch (rule.trigger) {
      case RuleTrigger.taskCreated:
        buffer.write('Task was just created');
        break;
      case RuleTrigger.deadlineApproaching:
        if (task.deadline != null) {
          buffer.write('Task deadline is approaching (${_formatDeadlineForNotification(task.deadline)})');
        } else {
          buffer.write('Deadline approaching trigger (no deadline set)');
        }
        break;
      case RuleTrigger.taskCompleted:
        buffer.write('Task was marked as completed');
        break;
      case RuleTrigger.taskDeleted:
        buffer.write('Task was deleted');
        break;
      case RuleTrigger.highPriorityTask:
        buffer.write('Task has high priority');
        break;
      default:
        buffer.write('Triggered by ${rule.trigger.name}');
    }
    
    // Explain the conditions that were met
    if (rule.conditions.isNotEmpty) {
      buffer.write(' and met conditions: ');
      final conditionExplanations = rule.conditions.map((condition) {
        switch (condition.type) {
          case RuleConditionType.priorityEquals:
            return 'priority is ${condition.value}';
          case RuleConditionType.hasDeadline:
            return 'has deadline set';
          case RuleConditionType.titleContains:
            return 'title contains "${condition.value}"';
          case RuleConditionType.deadlineWithin:
            return 'deadline within ${condition.value} hours';
          default:
            return '${condition.type.name} ${condition.operator ?? '='} ${condition.value}';
        }
      }).join(', ');
      buffer.write(conditionExplanations);
    }
    
    // Explain the actions that will be taken
    if (rule.actions.isNotEmpty) {
      buffer.write('. Actions: ');
      final actionExplanations = rule.actions.map((action) {
        switch (action.type) {
          case RuleActionType.sendNotification:
            return 'send notification "${action.parameters['title'] ?? 'Voice Butler'}"';
          case RuleActionType.sendReminder:
            final delay = action.parameters['delayMinutes'] ?? '60';
            return 'schedule reminder in $delay minutes';
          case RuleActionType.changePriority:
            return 'change priority to ${action.parameters['priority'] ?? 'medium'}';
          case RuleActionType.addToFocusMode:
            return 'add to focus mode';
          case RuleActionType.logActivity:
            return 'log activity';
          default:
            return action.type.name;
        }
      }).join(', ');
      buffer.write(actionExplanations);
    }
    
    return buffer.toString();
  }

  /// Handles rule execution failures gracefully
  Future<void> _handleRuleExecutionFailure(dynamic error, AutomationRule rule, Task task) async {
    try {
      // Log the rule execution failure with detailed context
      final errorLog = ActivityLog.errorOccurred(
        taskId: task.id,
        ruleId: rule.id,
        errorMessage: 'Failed to execute automation rule "${rule.name}": $error',
        additionalMetadata: {
          'ruleName': rule.name,
          'ruleId': rule.id,
          'triggerType': rule.trigger.name,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
          'actionsCount': rule.actions.length,
          'conditionsCount': rule.conditions.length,
        },
      );
      await _storageService.storeActivityLog(errorLog);
      
      if (kDebugMode) {
        print('Failed to execute rule "${rule.name}" for task "${task.title}": $error');
      }
    } catch (logError) {
      if (kDebugMode) {
        print('Failed to log rule execution error: $logError');
      }
    }
  }

  Future<void> _executeAction(RuleAction action, Task task, AutomationRule rule) async {
    switch (action.type) {
      case RuleActionType.sendNotification:
        await _sendNotification(action, task);
        break;
      case RuleActionType.sendReminder:
        await _scheduleReminder(action, task);
        break;
      case RuleActionType.changePriority:
        await _changePriority(action, task);
        break;
      case RuleActionType.addToFocusMode:
        await _addToFocusMode(task);
        break;
      case RuleActionType.logActivity:
        await _logActivity(action, task);
        break;
      default:
        if (kDebugMode) {
          print('Unhandled action type: ${action.type}');
        }
        break;
    }
  }

  Future<void> _sendNotification(RuleAction action, Task task) async {
    try {
      final title = action.parameters['title'] ?? 'Voice Butler';
      final message = action.parameters['message'] ?? 'Task notification';
      
      // Replace placeholders in message with detailed information
      final formattedMessage = message
          .replaceAll('{taskTitle}', task.title)
          .replaceAll('{priority}', task.priorityDisplayName)
          .replaceAll('{deadline}', _formatDeadlineForNotification(task.deadline))
          .replaceAll('{reason}', task.reason ?? 'No reason specified')
          .replaceAll('{createdAt}', _formatDateForNotification(task.createdAt));
      
      await _notificationService.showNotification(
        title: title,
        message: formattedMessage,
        taskId: task.id,
      );

      // Log the notification with detailed explanation
      final log = ActivityLog.notificationSent(
        taskId: task.id,
        taskTitle: task.title,
        notificationTitle: title,
        notificationMessage: formattedMessage,
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Sent notification: $title - $formattedMessage');
      }
    } catch (e) {
      // Handle notification failures gracefully
      await _handleNotificationFailure(e, task, action);
    }
  }

  /// Handles notification failures gracefully with logging and fallback
  Future<void> _handleNotificationFailure(dynamic error, Task task, RuleAction action) async {
    try {
      // Log the notification failure
      final errorLog = ActivityLog.errorOccurred(
        taskId: task.id,
        errorMessage: 'Failed to send notification: $error',
        additionalMetadata: {
          'actionType': action.type.name,
          'actionParameters': action.parameters,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
        },
      );
      await _storageService.storeActivityLog(errorLog);
      
      if (kDebugMode) {
        print('Failed to send notification for task ${task.title}: $error');
      }
      
      // Continue with other automation actions - don't let notification failure stop automation
    } catch (logError) {
      if (kDebugMode) {
        print('Failed to log notification error: $logError');
      }
    }
  }

  /// Formats deadline information for notifications
  String _formatDeadlineForNotification(DateTime? deadline) {
    if (deadline == null) return 'No deadline';
    
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      final overdue = now.difference(deadline);
      if (overdue.inDays > 0) {
        return 'Overdue by ${overdue.inDays} day${overdue.inDays == 1 ? '' : 's'}';
      } else if (overdue.inHours > 0) {
        return 'Overdue by ${overdue.inHours} hour${overdue.inHours == 1 ? '' : 's'}';
      } else {
        return 'Overdue by ${overdue.inMinutes} minute${overdue.inMinutes == 1 ? '' : 's'}';
      }
    } else {
      if (difference.inDays > 0) {
        return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
      } else if (difference.inHours > 0) {
        return 'Due in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
      } else {
        return 'Due in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
      }
    }
  }

  /// Formats date information for notifications
  String _formatDateForNotification(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
  }

  Future<void> _scheduleReminder(RuleAction action, Task task) async {
    try {
      final message = action.parameters['message'] ?? 'Task reminder';
      final delayMinutes = int.tryParse(action.parameters['delayMinutes'] ?? '60') ?? 60;
      
      // Create detailed reminder message with explanation
      final detailedMessage = _createDetailedReminderMessage(message, task, delayMinutes);
      
      await _backgroundService.scheduleJob(
        jobName: 'task_reminder',
        delay: Duration(minutes: delayMinutes),
        data: {
          'taskId': task.id,
          'message': detailedMessage,
          'reminderType': 'automation_reminder',
        },
      );

      // Log the scheduled reminder with explanation
      final log = ActivityLog.reminderSent(
        taskId: task.id,
        taskTitle: task.title,
        reminderMessage: detailedMessage,
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Scheduled reminder for task ${task.title} in $delayMinutes minutes: $detailedMessage');
      }
    } catch (e) {
      // Handle reminder scheduling failures gracefully
      await _handleReminderFailure(e, task, action);
    }
  }

  /// Creates a detailed reminder message with context
  String _createDetailedReminderMessage(String baseMessage, Task task, int delayMinutes) {
    final buffer = StringBuffer(baseMessage);
    
    // Add task context
    buffer.write(' - Task: "${task.title}"');
    
    // Add priority context
    if (task.priority == TaskPriority.high) {
      buffer.write(' (High Priority)');
    }
    
    // Add deadline context
    if (task.deadline != null) {
      buffer.write(' - ${_formatDeadlineForNotification(task.deadline)}');
    }
    
    // Add scheduling context
    buffer.write(' - Scheduled $delayMinutes minutes after automation trigger');
    
    return buffer.toString();
  }

  /// Handles reminder scheduling failures gracefully
  Future<void> _handleReminderFailure(dynamic error, Task task, RuleAction action) async {
    try {
      // Log the reminder failure
      final errorLog = ActivityLog.errorOccurred(
        taskId: task.id,
        errorMessage: 'Failed to schedule reminder: $error',
        additionalMetadata: {
          'actionType': action.type.name,
          'actionParameters': action.parameters,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
          'delayMinutes': action.parameters['delayMinutes'] ?? '60',
        },
      );
      await _storageService.storeActivityLog(errorLog);
      
      if (kDebugMode) {
        print('Failed to schedule reminder for task ${task.title}: $error');
      }
    } catch (logError) {
      if (kDebugMode) {
        print('Failed to log reminder error: $logError');
      }
    }
  }

  Future<void> _changePriority(RuleAction action, Task task) async {
    try {
      final newPriorityStr = action.parameters['priority'] ?? 'medium';
      final newPriority = TaskPriority.values.firstWhere(
        (p) => p.name == newPriorityStr,
        orElse: () => TaskPriority.medium,
      );
      
      if (task.priority != newPriority) {
        final updatedTask = task.copyWith(priority: newPriority);
        await _storageService.storeTask(updatedTask);
        
        // Log the priority change
        final log = ActivityLog.create(
          taskId: task.id,
          type: ActivityType.priorityChanged,
          description: 'Changed priority from ${task.priorityDisplayName} to ${newPriority.name}',
          metadata: {
            'oldPriority': task.priority.name,
            'newPriority': newPriority.name,
          },
        );
        await _storageService.storeActivityLog(log);
        
        if (kDebugMode) {
          print('Changed task ${task.title} priority to ${newPriority.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to change priority: $e');
      }
    }
  }

  Future<void> _addToFocusMode(Task task) async {
    try {
      // Log focus mode activation
      final log = ActivityLog.create(
        taskId: task.id,
        type: ActivityType.focusModeActivated,
        description: 'Added task "${task.title}" to focus mode',
        metadata: {
          'taskTitle': task.title,
          'priority': task.priority.name,
        },
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Added task ${task.title} to focus mode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add to focus mode: $e');
      }
    }
  }

  Future<void> _logActivity(RuleAction action, Task task) async {
    try {
      final message = action.parameters['message'] ?? 'Automation activity logged';
      
      final log = ActivityLog.create(
        taskId: task.id,
        type: ActivityType.automationApplied,
        description: message,
        metadata: {
          'taskTitle': task.title,
          'customMessage': message,
        },
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Logged activity: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log activity: $e');
      }
    }
  }

  /// Performs automatic cleanup of old soft-deleted tasks
  Future<int> performAutomaticCleanup() async {
    try {
      // Use the task repository's cleanup method
      final cleanedCount = await _storageService.performTaskAutoCleanup();
      
      if (cleanedCount > 0) {
        // Log the cleanup activity
        final log = ActivityLog.create(
          taskId: 'system',
          type: ActivityType.cleanupPerformed,
          description: 'Automatic cleanup completed: $cleanedCount tasks permanently deleted',
          metadata: {
            'cleanedCount': cleanedCount,
            'cleanupType': 'automatic',
          },
        );
        await _storageService.storeActivityLog(log);
        
        if (kDebugMode) {
          print('Automatic cleanup completed: $cleanedCount tasks removed');
        }
      }
      
      return cleanedCount;
    } catch (e) {
      if (kDebugMode) {
        print('Automatic cleanup failed: $e');
      }
      return 0;
    }
  }

  /// Schedules automatic cleanup to run periodically
  Future<void> scheduleAutomaticCleanup() async {
    // This would be called by the background service
    await performAutomaticCleanup();
  }

  /// Checks all tasks for deadline-approaching triggers and applies relevant rules
  Future<void> checkDeadlineReminders() async {
    try {
      final allTasks = _storageService.getAllTasks();
      final tasksWithApproachingDeadlines = allTasks
          .where((task) => task.hasDeadlineApproaching())
          .toList();

      for (final task in tasksWithApproachingDeadlines) {
        // Find rules that trigger on deadline approaching
        final deadlineRules = activeRules
            .where((rule) => rule.trigger == RuleTrigger.deadlineApproaching)
            .toList();

        for (final rule in deadlineRules) {
          if (_shouldTriggerRule(rule, task)) {
            await _executeRule(rule, task);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check deadline reminders: $e');
      }
    }
  }

  /// Applies automation rules when a task is created
  Future<void> onTaskCreated(Task task) async {
    try {
      // Find rules that trigger on task creation
      final creationRules = activeRules
          .where((rule) => rule.trigger == RuleTrigger.taskCreated)
          .toList();

      for (final rule in creationRules) {
        if (_shouldTriggerRule(rule, task)) {
          await _executeRule(rule, task);
        }
      }

      // If task has a deadline, schedule deadline reminders
      if (task.deadline != null) {
        await _scheduleDeadlineReminders(task);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to apply creation rules: $e');
      }
    }
  }

  /// Executes preset workflows for a task
  Future<void> executePresetWorkflowsForTask(Task task) async {
    try {
      // This method can be called by the preset workflow provider
      // to execute automation rules for a specific task
      await applyAutomationRules(task);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to execute preset workflows for task: $e');
      }
    }
  }

  /// Applies automation rules when a task is completed
  Future<void> onTaskCompleted(Task task) async {
    try {
      // Find rules that trigger on task completion
      final completionRules = activeRules
          .where((rule) => rule.trigger == RuleTrigger.taskCompleted)
          .toList();

      for (final rule in completionRules) {
        if (_shouldTriggerRule(rule, task)) {
          await _executeRule(rule, task);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to apply completion rules: $e');
      }
    }
  }

  /// Applies automation rules when a task is deleted
  Future<void> onTaskDeleted(Task task) async {
    try {
      // Find rules that trigger on task deletion
      final deletionRules = activeRules
          .where((rule) => rule.trigger == RuleTrigger.taskDeleted)
          .toList();

      for (final rule in deletionRules) {
        if (_shouldTriggerRule(rule, task)) {
          await _executeRule(rule, task);
        }
      }

      // Note: Reminder cancellation not implemented in background service stub
    } catch (e) {
      if (kDebugMode) {
        print('Failed to apply deletion rules: $e');
      }
    }
  }

  /// Schedules deadline reminders for a task
  Future<void> _scheduleDeadlineReminders(Task task) async {
    if (task.deadline == null) return;

    try {
      final now = DateTime.now();
      final deadline = task.deadline!;
      
      // Schedule 24-hour reminder
      final oneDayBefore = deadline.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now)) {
        await _backgroundService.scheduleJob(
          jobName: 'task_reminder',
          delay: oneDayBefore.difference(now),
          data: {
            'taskId': task.id,
            'reminderType': 'deadline_24h',
          },
        );
      }

      // Schedule 1-hour reminder
      final oneHourBefore = deadline.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(now)) {
        await _backgroundService.scheduleJob(
          jobName: 'task_reminder',
          delay: oneHourBefore.difference(now),
          data: {
            'taskId': task.id,
            'reminderType': 'deadline_1h',
          },
        );
      }

      if (kDebugMode) {
        print('Scheduled deadline reminders for task: ${task.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule deadline reminders: $e');
      }
    }
  }
}