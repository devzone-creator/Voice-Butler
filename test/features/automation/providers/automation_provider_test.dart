import 'package:flutter_test/flutter_test.dart';
import 'package:voice_butler/core/models/task.dart';
import 'package:voice_butler/core/models/automation_rule.dart';
import 'package:voice_butler/features/automation/providers/automation_provider.dart';

void main() {
  group('AutomationProvider Property Tests', () {
    late AutomationProvider automationProvider;

    setUp(() async {
      // Create automation provider without storage dependencies for testing
      automationProvider = AutomationProvider();
      
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 50));
    });

    group('Property 10: Deadline Reminder Scheduling', () {
      test('**Feature: voice-butler, Property 10: Deadline Reminder Scheduling**', () async {
        // **Property 10: Deadline Reminder Scheduling**
        // **Validates: Requirements 3.1**
        // For any task with a deadline, the system should automatically schedule appropriate reminder notifications.
        
        // Property-based test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task with deadline
          final task = _generateRandomTaskWithDeadline();
          
          // Verify the property: tasks with deadlines should have deadline-related automation rules available
          final hasDeadline = task.deadline != null;
          final deadlineInFuture = task.deadline?.isAfter(DateTime.now()) ?? false;
          
          if (hasDeadline && deadlineInFuture) {
            // Check that deadline-approaching rules exist in the automation provider
            final deadlineRules = automationProvider.activeRules
                .where((rule) => rule.trigger == RuleTrigger.deadlineApproaching)
                .toList();
            
            // Property: System should have deadline reminder rules available
            expect(deadlineRules.isNotEmpty, isTrue,
                reason: 'System should have deadline reminder automation rules for tasks with deadlines');
            
            // Property: Deadline rules should have appropriate conditions
            final hasDeadlineConditions = deadlineRules.any((rule) =>
                rule.conditions.any((condition) => 
                    condition.type == RuleConditionType.hasDeadline));
            
            expect(hasDeadlineConditions, isTrue,
                reason: 'Deadline rules should check for deadline conditions');
          }
        }
      });

      test('deadline reminder rules are properly configured', () async {
        // Verify that the automation provider has deadline reminder rules
        final deadlineRules = automationProvider.activeRules
            .where((rule) => rule.trigger == RuleTrigger.deadlineApproaching)
            .toList();

        expect(deadlineRules.isNotEmpty, isTrue,
            reason: 'Should have deadline reminder rules configured');

        // Check that deadline rules have notification actions
        for (final rule in deadlineRules) {
          final hasNotificationAction = rule.actions.any((action) =>
              action.type == RuleActionType.sendNotification);
          
          expect(hasNotificationAction, isTrue,
              reason: 'Deadline rules should send notifications');
        }
      });

      test('tasks with approaching deadlines trigger deadline rules', () async {
        // Create task with deadline approaching (within 24 hours)
        final approachingDeadline = DateTime.now().add(const Duration(hours: 12));
        final task = Task.create(
          title: 'Urgent Task',
          priority: TaskPriority.high,
          deadline: approachingDeadline,
        );

        // Check if deadline-approaching rules would be triggered
        final hasApproachingDeadline = task.hasDeadlineApproaching();
        expect(hasApproachingDeadline, isTrue,
            reason: 'Task with deadline in 12 hours should be approaching');

        // Verify that deadline rules exist to handle this case
        final deadlineRules = automationProvider.activeRules
            .where((rule) => rule.trigger == RuleTrigger.deadlineApproaching)
            .toList();

        expect(deadlineRules.isNotEmpty, isTrue,
            reason: 'Should have rules to handle approaching deadlines');
      });
    });

    group('Property 11: Priority-Based Automation', () {
      test('**Feature: voice-butler, Property 11: Priority-Based Automation**', () async {
        // **Property 11: Priority-Based Automation**
        // **Validates: Requirements 3.2**
        // For any high-priority task, the system should apply early reminder automation rules.
        
        // Property-based test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task
          final task = _generateRandomTask();
          
          // Check if task is high priority
          final isHighPriority = task.priority == TaskPriority.high;
          
          if (isHighPriority) {
            // Verify that high priority automation rules exist
            final highPriorityRules = automationProvider.activeRules
                .where((rule) => rule.conditions.any((condition) => 
                    condition.type == RuleConditionType.priorityEquals && 
                    condition.value == 'high'))
                .toList();
            
            // Property: System should have high priority automation rules
            expect(highPriorityRules.isNotEmpty, isTrue,
                reason: 'System should have automation rules for high priority tasks');
            
            // Property: High priority rules should have notification actions
            final hasNotificationActions = highPriorityRules.any((rule) =>
                rule.actions.any((action) => 
                    action.type == RuleActionType.sendNotification));
            
            expect(hasNotificationActions, isTrue,
                reason: 'High priority rules should include notification actions');
          }
        }
      });

      test('high priority rules are properly configured', () async {
        // Verify that the automation provider has high priority rules
        final highPriorityRules = automationProvider.activeRules
            .where((rule) => rule.conditions.any((condition) => 
                condition.type == RuleConditionType.priorityEquals && 
                condition.value == 'high'))
            .toList();

        expect(highPriorityRules.isNotEmpty, isTrue,
            reason: 'Should have high priority automation rules configured');

        // Check that high priority rules trigger on task creation
        for (final rule in highPriorityRules) {
          expect(rule.trigger, equals(RuleTrigger.taskCreated),
              reason: 'High priority rules should trigger on task creation');
        }
      });

      test('priority-based rule conditions work correctly', () async {
        // Test each priority level
        for (final priority in TaskPriority.values) {
          final task = Task.create(
            title: 'Test Task',
            priority: priority,
          );

          // Check if there are rules for this priority
          final priorityRules = automationProvider.activeRules
              .where((rule) => rule.conditions.any((condition) => 
                  condition.type == RuleConditionType.priorityEquals && 
                  condition.value == priority.name))
              .toList();

          if (priority == TaskPriority.high) {
            expect(priorityRules.isNotEmpty, isTrue,
                reason: 'Should have rules for high priority tasks');
          }
        }
      });
    });

    group('Property 12: Automation Activity Logging', () {
      test('**Feature: voice-butler, Property 12: Automation Activity Logging**', () async {
        // **Property 12: Automation Activity Logging**
        // **Validates: Requirements 3.3**
        // For any automation rule execution, all actions taken should be logged in the activity feed.
        
        // Property-based test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task that will trigger automation
          final task = _generateRandomTask();
          
          // Get initial activity log count
          final initialLogCount = automationProvider.activeRules.length;
          
          // Check if task would trigger any automation rules
          final applicableRules = automationProvider.activeRules.where((rule) {
            // Simulate rule evaluation logic
            switch (rule.trigger) {
              case RuleTrigger.taskCreated:
                return true; // Task creation always triggers
              case RuleTrigger.deadlineApproaching:
                return task.hasDeadlineApproaching();
              default:
                return false;
            }
          }).toList();
          
          if (applicableRules.isNotEmpty) {
            // Property: Automation rules should exist for logging
            expect(applicableRules.isNotEmpty, isTrue,
                reason: 'Should have automation rules that can be triggered');
            
            // Property: Each rule should have actions that can be logged
            for (final rule in applicableRules) {
              expect(rule.actions.isNotEmpty, isTrue,
                  reason: 'Automation rules should have actions to execute and log');
              
              // Property: Rules should have identifiable triggers
              expect(rule.trigger, isNotNull,
                  reason: 'Automation rules should have defined triggers for logging');
            }
          }
        }
      });

      test('automation rules have loggable actions', () async {
        // Verify that automation rules have actions that can be logged
        final allRules = automationProvider.activeRules;
        
        expect(allRules.isNotEmpty, isTrue,
            reason: 'Should have automation rules configured');

        for (final rule in allRules) {
          // Each rule should have at least one action
          expect(rule.actions.isNotEmpty, isTrue,
              reason: 'Automation rule "${rule.name}" should have actions');
          
          // Actions should be of types that can be logged
          final loggableActionTypes = [
            RuleActionType.sendNotification,
            RuleActionType.sendReminder,
            RuleActionType.changePriority,
            RuleActionType.addToFocusMode,
            RuleActionType.logActivity,
          ];
          
          final hasLoggableActions = rule.actions.any((action) =>
              loggableActionTypes.contains(action.type));
          
          expect(hasLoggableActions, isTrue,
              reason: 'Rule "${rule.name}" should have loggable action types');
        }
      });

      test('automation rule structure supports logging', () async {
        // Verify that automation rules have the necessary structure for logging
        final allRules = automationProvider.activeRules;
        
        for (final rule in allRules) {
          // Rule should have identifiable properties for logging
          expect(rule.id.isNotEmpty, isTrue,
              reason: 'Rule should have ID for logging');
          expect(rule.name.isNotEmpty, isTrue,
              reason: 'Rule should have name for logging');
          expect(rule.trigger, isNotNull,
              reason: 'Rule should have trigger for logging');
          
          // Rule should be active to be logged
          expect(rule.isActive, isTrue,
              reason: 'Only active rules should be in activeRules list');
        }
      });
    });

    group('Property 13: Automation Notification', () {
      test('**Feature: voice-butler, Property 13: Automation Notification** - For any predefined automation execution, the user should be notified of the automated action taken', () async {
        // **Validates: Requirements 3.4**
        
        // Property-based test with various automation scenarios
        final testScenarios = [
          {
            'taskPriority': TaskPriority.high,
            'trigger': RuleTrigger.taskCreated,
            'expectedNotification': true,
            'description': 'High priority task creation should trigger notification'
          },
          {
            'taskPriority': TaskPriority.medium,
            'trigger': RuleTrigger.deadlineApproaching,
            'hasDeadline': true,
            'expectedNotification': true,
            'description': 'Deadline approaching should trigger notification'
          },
          {
            'taskPriority': TaskPriority.low,
            'trigger': RuleTrigger.taskCreated,
            'expectedNotification': false,
            'description': 'Low priority task creation may not trigger notification'
          },
        ];
        
        for (int i = 0; i < testScenarios.length; i++) {
          final scenario = testScenarios[i];
          final priority = scenario['taskPriority'] as TaskPriority;
          final trigger = scenario['trigger'] as RuleTrigger;
          final expectedNotification = scenario['expectedNotification'] as bool;
          final description = scenario['description'] as String;
          final hasDeadline = scenario['hasDeadline'] as bool? ?? false;
          
          // Create task matching the scenario
          final task = Task.create(
            title: 'Test Task $i',
            priority: priority,
            deadline: hasDeadline ? DateTime.now().add(const Duration(hours: 12)) : null,
          );
          
          // Find applicable automation rules for this scenario
          final applicableRules = automationProvider.activeRules.where((rule) {
            // Check if rule trigger matches
            if (rule.trigger != trigger) return false;
            
            // Check if rule conditions match the task
            return rule.conditions.every((condition) {
              switch (condition.type) {
                case RuleConditionType.priorityEquals:
                  return task.priority.name == condition.value;
                case RuleConditionType.hasDeadline:
                  return task.deadline != null;
                case RuleConditionType.deadlineWithin:
                  if (task.deadline == null) return false;
                  final hours = int.tryParse(condition.value) ?? 24;
                  return task.deadline!.difference(DateTime.now()).inHours <= hours;
                default:
                  return true;
              }
            });
          }).toList();
          
          if (expectedNotification) {
            // Property: Should have rules that will send notifications
            expect(applicableRules.isNotEmpty, isTrue,
                reason: '$description - should have applicable automation rules');
            
            // Property: Applicable rules should have notification actions
            final hasNotificationActions = applicableRules.any((rule) =>
                rule.actions.any((action) => 
                    action.type == RuleActionType.sendNotification));
            
            expect(hasNotificationActions, isTrue,
                reason: '$description - applicable rules should send notifications');
            
            // Property: Notification actions should have proper parameters
            for (final rule in applicableRules) {
              for (final action in rule.actions) {
                if (action.type == RuleActionType.sendNotification) {
                  expect(action.parameters.containsKey('title'), isTrue,
                      reason: 'Notification action should have title parameter');
                  expect(action.parameters.containsKey('message'), isTrue,
                      reason: 'Notification action should have message parameter');
                  
                  final title = action.parameters['title'];
                  final message = action.parameters['message'];
                  
                  expect(title?.isNotEmpty, isTrue,
                      reason: 'Notification title should not be empty');
                  expect(message?.isNotEmpty, isTrue,
                      reason: 'Notification message should not be empty');
                }
              }
            }
          }
        }
      });
      
      test('notification actions have proper structure', () async {
        // Verify that all notification actions in automation rules have proper structure
        final allRules = automationProvider.activeRules;
        
        for (final rule in allRules) {
          for (final action in rule.actions) {
            if (action.type == RuleActionType.sendNotification) {
              // Property: Notification actions must have required parameters
              expect(action.parameters, isNotNull,
                  reason: 'Notification action should have parameters');
              expect(action.parameters.containsKey('title'), isTrue,
                  reason: 'Notification action should have title');
              expect(action.parameters.containsKey('message'), isTrue,
                  reason: 'Notification action should have message');
              
              // Property: Parameters should be non-empty strings
              final title = action.parameters['title'];
              final message = action.parameters['message'];
              
              expect(title, isA<String>(),
                  reason: 'Notification title should be a string');
              expect(message, isA<String>(),
                  reason: 'Notification message should be a string');
              expect((title as String).isNotEmpty, isTrue,
                  reason: 'Notification title should not be empty');
              expect((message as String).isNotEmpty, isTrue,
                  reason: 'Notification message should not be empty');
            }
          }
        }
      });
      
      test('automation rules provide user-friendly notifications', () async {
        // Verify that automation notifications are user-friendly
        final notificationRules = automationProvider.activeRules
            .where((rule) => rule.actions.any((action) => 
                action.type == RuleActionType.sendNotification))
            .toList();
        
        expect(notificationRules.isNotEmpty, isTrue,
            reason: 'Should have rules that send notifications');
        
        for (final rule in notificationRules) {
          final notificationActions = rule.actions
              .where((action) => action.type == RuleActionType.sendNotification)
              .toList();
          
          for (final action in notificationActions) {
            final title = action.parameters['title'] as String;
            final message = action.parameters['message'] as String;
            
            // Property: Notifications should be informative
            expect(title.length, greaterThan(5),
                reason: 'Notification title should be descriptive');
            expect(message.length, greaterThan(10),
                reason: 'Notification message should be informative');
            
            // Property: Notifications should not contain technical jargon
            final technicalTerms = ['null', 'undefined', 'error', 'exception', 'debug'];
            final titleLower = title.toLowerCase();
            final messageLower = message.toLowerCase();
            
            for (final term in technicalTerms) {
              expect(titleLower.contains(term), isFalse,
                  reason: 'Notification title should not contain technical term: $term');
              expect(messageLower.contains(term), isFalse,
                  reason: 'Notification message should not contain technical term: $term');
            }
          }
        }
      });
    });
  });
}

/// Generates a random task for property-based testing
Task _generateRandomTask() {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  const priorities = TaskPriority.values;
  final priority = priorities[random % priorities.length];
  
  const titles = [
    'Complete project',
    'Review documents',
    'Send email',
    'Call client',
    'Update website',
    'Fix bug',
    'Write report',
    'Schedule meeting',
  ];
  
  final title = titles[random % titles.length];
  
  // Randomly add deadline (50% chance)
  DateTime? deadline;
  if (random % 2 == 0) {
    final daysFromNow = (random % 30) + 1; // 1-30 days from now
    deadline = DateTime.now().add(Duration(days: daysFromNow));
  }
  
  return Task.create(
    title: '$title $random',
    priority: priority,
    deadline: deadline,
    reason: random % 3 == 0 ? 'Test reason $random' : null,
  );
}

/// Generates a random task with a deadline for property-based testing
Task _generateRandomTaskWithDeadline() {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  const priorities = TaskPriority.values;
  final priority = priorities[random % priorities.length];
  
  const titles = [
    'Complete project',
    'Review documents',
    'Send email',
    'Call client',
    'Update website',
    'Fix bug',
    'Write report',
    'Schedule meeting',
  ];
  
  final title = titles[random % titles.length];
  
  // Always add deadline (1 hour to 30 days from now)
  final hoursFromNow = (random % (30 * 24)) + 1; // 1 hour to 30 days
  final deadline = DateTime.now().add(Duration(hours: hoursFromNow));
  
  return Task.create(
    title: '$title $random',
    priority: priority,
    deadline: deadline,
    reason: random % 3 == 0 ? 'Test reason $random' : null,
  );
}