import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/core/services/storage_service.dart';
import 'package:voice_butler/core/models/task.dart';
import 'package:voice_butler/core/models/automation_rule.dart';
import 'package:voice_butler/core/models/activity_log.dart';

void main() {
  group('Storage Service Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('./test/hive_test_db');
      storageService = StorageService.instance;
      await storageService.initialize();
    });

    tearDownAll(() async {
      await storageService.close();
    });

    setUp(() async {
      // Clear all data before each test
      await storageService.clearAll();
    });

    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 24: Task Data Persistence** - For any task creation or modification, changes should be immediately persisted to the backend database', () {
        // **Validates: Requirements 6.1**
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task data
          final taskData = _generateRandomTaskData(i);
          
          // Create task
          final originalTask = Task.create(
            title: taskData['title'],
            priority: taskData['priority'],
            reason: taskData['reason'],
            deadline: taskData['deadline'],
          );
          
          // Store task and verify immediate persistence
          storageService.storeTask(originalTask);
          
          // Retrieve task immediately and verify it matches
          final retrievedTask = storageService.getTask(originalTask.id);
          expect(retrievedTask, isNotNull,
              reason: 'Task should be immediately retrievable after storage');
          expect(retrievedTask!.id, equals(originalTask.id));
          expect(retrievedTask.title, equals(originalTask.title));
          expect(retrievedTask.priority, equals(originalTask.priority));
          expect(retrievedTask.reason, equals(originalTask.reason));
          expect(retrievedTask.deadline, equals(originalTask.deadline));
          expect(retrievedTask.status, equals(originalTask.status));
          expect(retrievedTask.createdAt, equals(originalTask.createdAt));
          
          // Modify task and verify persistence of changes
          final modifiedTask = originalTask.copyWith(
            title: '${taskData['title']} - Modified',
            priority: TaskPriority.high,
            reason: 'Modified reason',
          );
          
          // Update task
          storageService.updateTask(modifiedTask);
          
          // Retrieve updated task and verify changes persisted
          final updatedRetrievedTask = storageService.getTask(originalTask.id);
          expect(updatedRetrievedTask, isNotNull,
              reason: 'Updated task should be immediately retrievable');
          expect(updatedRetrievedTask!.title, equals(modifiedTask.title),
              reason: 'Title modification should be persisted');
          expect(updatedRetrievedTask.priority, equals(modifiedTask.priority),
              reason: 'Priority modification should be persisted');
          expect(updatedRetrievedTask.reason, equals(modifiedTask.reason),
              reason: 'Reason modification should be persisted');
          
          // Verify original fields that shouldn't change are preserved
          expect(updatedRetrievedTask.id, equals(originalTask.id));
          expect(updatedRetrievedTask.createdAt, equals(originalTask.createdAt));
          expect(updatedRetrievedTask.status, equals(originalTask.status));
        }
      });
      
      test('Task state transitions persist correctly', () {
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task
          final taskData = _generateRandomTaskData(i);
          final originalTask = Task.create(
            title: taskData['title'],
            priority: taskData['priority'],
            reason: taskData['reason'],
            deadline: taskData['deadline'],
          );
          
          // Store original task
          storageService.storeTask(originalTask);
          
          // Test completion transition persistence
          final completedTask = originalTask.markCompleted();
          storageService.updateTask(completedTask);
          
          final retrievedCompleted = storageService.getTask(originalTask.id);
          expect(retrievedCompleted!.status, equals(TaskStatus.completed));
          expect(retrievedCompleted.completedAt, isNotNull);
          expect(retrievedCompleted.completedAt, equals(completedTask.completedAt));
          
          // Test soft delete transition persistence
          final deletedTask = completedTask.markSoftDeleted();
          storageService.updateTask(deletedTask);
          
          final retrievedDeleted = storageService.getTask(originalTask.id);
          expect(retrievedDeleted!.status, equals(TaskStatus.softDeleted));
          expect(retrievedDeleted.isDeleted, isTrue);
          expect(retrievedDeleted.recentDeleted, isTrue);
          expect(retrievedDeleted.deletedAt, isNotNull);
          expect(retrievedDeleted.deletedAt, equals(deletedTask.deletedAt));
          
          // Test restore transition persistence
          final restoredTask = deletedTask.restore();
          storageService.updateTask(restoredTask);
          
          final retrievedRestored = storageService.getTask(originalTask.id);
          expect(retrievedRestored!.status, equals(TaskStatus.pending));
          expect(retrievedRestored.isDeleted, isFalse);
          expect(retrievedRestored.recentDeleted, isFalse);
          expect(retrievedRestored.deletedAt, isNull);
        }
      });
      
      test('Cache consistency with storage', () {
        // Run property test with 50 iterations (fewer due to cache operations)
        for (int i = 0; i < 50; i++) {
          // Generate random task
          final taskData = _generateRandomTaskData(i);
          final task = Task.create(
            title: taskData['title'],
            priority: taskData['priority'],
            reason: taskData['reason'],
            deadline: taskData['deadline'],
          );
          
          // Store task
          storageService.storeTask(task);
          
          // Verify task is in cache and storage
          final cachedTask = storageService.getTask(task.id);
          expect(cachedTask, isNotNull);
          expect(cachedTask!.id, equals(task.id));
          
          // Invalidate cache and verify storage persistence
          storageService.invalidateCaches();
          
          final storageTask = storageService.getTask(task.id);
          expect(storageTask, isNotNull,
              reason: 'Task should persist in storage even after cache invalidation');
          expect(storageTask!.id, equals(task.id));
          expect(storageTask.title, equals(task.title));
          expect(storageTask.priority, equals(task.priority));
          
          // Refresh cache and verify consistency
          storageService.refreshCaches();
          
          final refreshedTask = storageService.getTask(task.id);
          expect(refreshedTask, isNotNull);
          expect(refreshedTask!.id, equals(task.id));
          expect(refreshedTask.title, equals(task.title));
        }
      });
      
      test('Automation rule persistence', () {
        // Run property test with 50 iterations
        for (int i = 0; i < 50; i++) {
          // Generate random automation rule
          final rule = AutomationRule.create(
            name: 'Test Rule $i',
            trigger: RuleTrigger.values[i % RuleTrigger.values.length],
            conditions: [
              RuleCondition.priorityEquals('high'),
              RuleCondition.hasDeadline(),
            ],
            actions: [
              RuleAction.sendNotification(
                title: 'Test Notification',
                message: 'Test message $i',
              ),
            ],
            description: 'Test rule description $i',
          );
          
          // Store rule
          storageService.storeAutomationRule(rule);
          
          // Retrieve and verify persistence
          final retrievedRule = storageService.getAutomationRule(rule.id);
          expect(retrievedRule, isNotNull);
          expect(retrievedRule!.id, equals(rule.id));
          expect(retrievedRule.name, equals(rule.name));
          expect(retrievedRule.trigger, equals(rule.trigger));
          expect(retrievedRule.conditions.length, equals(rule.conditions.length));
          expect(retrievedRule.actions.length, equals(rule.actions.length));
          expect(retrievedRule.description, equals(rule.description));
          expect(retrievedRule.isActive, equals(rule.isActive));
          
          // Test rule modification persistence
          final modifiedRule = rule.copyWith(
            name: 'Modified Rule $i',
            isActive: false,
          );
          
          storageService.storeAutomationRule(modifiedRule);
          
          final retrievedModified = storageService.getAutomationRule(rule.id);
          expect(retrievedModified!.name, equals(modifiedRule.name));
          expect(retrievedModified.isActive, equals(modifiedRule.isActive));
        }
      });
      
      test('Activity log persistence', () {
        // Run property test with 50 iterations
        for (int i = 0; i < 50; i++) {
          // Generate random activity log
          final log = ActivityLog.create(
            taskId: 'task_$i',
            type: ActivityType.values[i % ActivityType.values.length],
            description: 'Test activity $i',
            metadata: {
              'testKey': 'testValue$i',
              'iteration': i.toString(),
            },
          );
          
          // Store log
          storageService.storeActivityLog(log);
          
          // Retrieve and verify persistence
          final retrievedLog = storageService.getActivityLog(log.id);
          expect(retrievedLog, isNotNull);
          expect(retrievedLog!.id, equals(log.id));
          expect(retrievedLog.taskId, equals(log.taskId));
          expect(retrievedLog.type, equals(log.type));
          expect(retrievedLog.description, equals(log.description));
          expect(retrievedLog.metadata['testKey'], equals(log.metadata['testKey']));
          expect(retrievedLog.metadata['iteration'], equals(log.metadata['iteration']));
          expect(retrievedLog.timestamp, equals(log.timestamp));
          expect(retrievedLog.isSystemGenerated, equals(log.isSystemGenerated));
        }
      });
      
      test('Bulk operations maintain consistency', () {
        // Test bulk storage and retrieval
        final tasks = <Task>[];
        
        // Generate and store multiple tasks
        for (int i = 0; i < 20; i++) {
          final taskData = _generateRandomTaskData(i);
          final task = Task.create(
            title: taskData['title'],
            priority: taskData['priority'],
            reason: taskData['reason'],
            deadline: taskData['deadline'],
          );
          tasks.add(task);
          storageService.storeTask(task);
        }
        
        // Verify all tasks are retrievable
        final allTasks = storageService.getAllTasks();
        expect(allTasks.length, greaterThanOrEqualTo(tasks.length));
        
        for (final originalTask in tasks) {
          final retrievedTask = storageService.getTask(originalTask.id);
          expect(retrievedTask, isNotNull,
              reason: 'Each stored task should be retrievable');
          expect(retrievedTask!.id, equals(originalTask.id));
          expect(retrievedTask.title, equals(originalTask.title));
        }
        
        // Test filtered retrieval
        final pendingTasks = storageService.getPendingTasks();
        expect(pendingTasks.length, equals(tasks.length),
            reason: 'All new tasks should be pending');
        
        // Modify some tasks and verify persistence
        for (int i = 0; i < 5; i++) {
          final completedTask = tasks[i].markCompleted();
          storageService.updateTask(completedTask);
        }
        
        final completedTasks = storageService.getCompletedTasks();
        expect(completedTasks.length, equals(5),
            reason: 'Completed tasks should be retrievable');
        
        final remainingPending = storageService.getPendingTasks();
        expect(remainingPending.length, equals(tasks.length - 5),
            reason: 'Remaining tasks should still be pending');
      });
    });
    
    group('Unit Tests', () {
      test('Storage service initialization', () {
        expect(storageService.tasksBox, isNotNull);
        expect(storageService.automationRulesBox, isNotNull);
        expect(storageService.activityLogsBox, isNotNull);
        expect(storageService.settingsBox, isNotNull);
      });
      
      test('Settings persistence', () async {
        // Test string setting
        await storageService.setSetting('testString', 'testValue');
        expect(storageService.getSetting<String>('testString'), equals('testValue'));
        
        // Test boolean setting
        await storageService.setSetting('testBool', true);
        expect(storageService.getSetting<bool>('testBool'), isTrue);
        
        // Test integer setting
        await storageService.setSetting('testInt', 42);
        expect(storageService.getSetting<int>('testInt'), equals(42));
        
        // Test default value
        expect(storageService.getSetting<String>('nonExistent', defaultValue: 'default'), 
               equals('default'));
        
        // Test setting deletion
        await storageService.deleteSetting('testString');
        expect(storageService.getSetting<String>('testString'), isNull);
      });
      
      test('Cache statistics', () {
        final stats = storageService.getCacheStatistics();
        expect(stats, containsPair('taskCacheSize', isA<int>()));
        expect(stats, containsPair('ruleCacheSize', isA<int>()));
        expect(stats, containsPair('logCacheSize', isA<int>()));
        expect(stats, containsPair('taskCacheValid', isA<bool>()));
        expect(stats, containsPair('ruleCacheValid', isA<bool>()));
        expect(stats, containsPair('logCacheValid', isA<bool>()));
      });
      
      test('Storage statistics', () {
        final stats = storageService.getStorageStatistics();
        expect(stats, containsPair('totalTasks', isA<int>()));
        expect(stats, containsPair('totalRules', isA<int>()));
        expect(stats, containsPair('totalLogs', isA<int>()));
        expect(stats, containsPair('pendingTasks', isA<int>()));
        expect(stats, containsPair('completedTasks', isA<int>()));
        expect(stats, containsPair('activeRules', isA<int>()));
      });
    });
  });
}

/// Generates random task data for property-based testing
Map<String, dynamic> _generateRandomTaskData(int seed) {
  // Use seed for deterministic randomness in tests
  final random = _SeededRandom(seed);
  
  final titles = [
    'Complete project documentation',
    'Review code changes',
    'Attend team meeting',
    'Fix critical bug',
    'Update dependencies',
    'Write unit tests',
    'Deploy to production',
    'Backup database',
    'Update user interface',
    'Optimize performance',
    'Refactor legacy code',
    'Implement new feature',
    'Test mobile app',
    'Update API documentation',
    'Security audit',
  ];
  
  final reasons = [
    'High priority request',
    'Customer requirement',
    'Security update needed',
    'Performance improvement',
    'Bug fix required',
    'Feature enhancement',
    null, // Some tasks may not have a reason
    'Maintenance task',
    'Compliance requirement',
    'User feedback',
    'Technical debt',
    'Code quality improvement',
  ];
  
  final priorities = TaskPriority.values;
  
  return {
    'title': titles[random.nextInt(titles.length)],
    'priority': priorities[random.nextInt(priorities.length)],
    'reason': reasons[random.nextInt(reasons.length)],
    'deadline': random.nextBool() 
        ? DateTime.now().add(Duration(days: random.nextInt(30)))
        : null,
  };
}

/// Simple seeded random number generator for deterministic tests
class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
  
  bool nextBool() {
    return nextInt(2) == 1;
  }
}