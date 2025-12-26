import 'package:flutter_test/flutter_test.dart';
import 'package:voice_butler/core/models/task.dart';

void main() {
  group('Task Model Tests', () {
    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 4: Task Creation Consistency** - For any confirmed task preview, creating the task should result in a stored task that matches the preview data exactly', () {
        // **Validates: Requirements 1.4**
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random task data
          final taskData = _generateRandomTaskData(i);
          
          // Create task using the factory method (simulating task creation from preview)
          final createdTask = Task.create(
            title: taskData['title'],
            priority: taskData['priority'],
            reason: taskData['reason'],
            deadline: taskData['deadline'],
          );
          
          // Verify that the created task matches the input data exactly
          expect(createdTask.title, equals(taskData['title']),
              reason: 'Task title should match input data');
          expect(createdTask.priority, equals(taskData['priority']),
              reason: 'Task priority should match input data');
          expect(createdTask.reason, equals(taskData['reason']),
              reason: 'Task reason should match input data');
          expect(createdTask.deadline, equals(taskData['deadline']),
              reason: 'Task deadline should match input data');
          
          // Verify default values are set correctly
          expect(createdTask.status, equals(TaskStatus.pending),
              reason: 'New task should have pending status');
          expect(createdTask.isDeleted, isFalse,
              reason: 'New task should not be deleted');
          expect(createdTask.recentDeleted, isFalse,
              reason: 'New task should not be in recent deleted');
          expect(createdTask.completedAt, isNull,
              reason: 'New task should not have completion time');
          expect(createdTask.deletedAt, isNull,
              reason: 'New task should not have deletion time');
          
          // Verify ID is generated and unique
          expect(createdTask.id, isNotEmpty,
              reason: 'Task should have a generated ID');
          expect(createdTask.createdAt, isNotNull,
              reason: 'Task should have creation timestamp');
          
          // Verify creation timestamp is recent (within last second)
          final now = DateTime.now();
          final timeDiff = now.difference(createdTask.createdAt).inMilliseconds;
          expect(timeDiff, lessThan(1000),
              reason: 'Creation timestamp should be recent');
        }
      });
      
      test('Task copyWith preserves data integrity', () {
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random original task
          final originalData = _generateRandomTaskData(i);
          final originalTask = Task.create(
            title: originalData['title'],
            priority: originalData['priority'],
            reason: originalData['reason'],
            deadline: originalData['deadline'],
          );
          
          // Test partial updates (only update title)
          final updatedTask = originalTask.copyWith(
            title: 'Updated Title $i',
          );
          
          // Verify updated field
          expect(updatedTask.title, equals('Updated Title $i'));
          
          // Verify unchanged fields are preserved
          expect(updatedTask.id, equals(originalTask.id));
          expect(updatedTask.priority, equals(originalTask.priority));
          expect(updatedTask.reason, equals(originalTask.reason));
          expect(updatedTask.deadline, equals(originalTask.deadline));
          expect(updatedTask.status, equals(originalTask.status));
          expect(updatedTask.createdAt, equals(originalTask.createdAt));
          expect(updatedTask.completedAt, equals(originalTask.completedAt));
          expect(updatedTask.deletedAt, equals(originalTask.deletedAt));
          expect(updatedTask.isDeleted, equals(originalTask.isDeleted));
          expect(updatedTask.recentDeleted, equals(originalTask.recentDeleted));
        }
      });
      
      test('Task JSON serialization round-trip preserves data', () {
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
          
          // Convert to JSON and back
          final json = originalTask.toJson();
          final deserializedTask = Task.fromJson(json);
          
          // Verify all fields are preserved
          expect(deserializedTask.id, equals(originalTask.id));
          expect(deserializedTask.title, equals(originalTask.title));
          expect(deserializedTask.priority, equals(originalTask.priority));
          expect(deserializedTask.reason, equals(originalTask.reason));
          expect(deserializedTask.deadline, equals(originalTask.deadline));
          expect(deserializedTask.status, equals(originalTask.status));
          expect(deserializedTask.createdAt, equals(originalTask.createdAt));
          expect(deserializedTask.completedAt, equals(originalTask.completedAt));
          expect(deserializedTask.deletedAt, equals(originalTask.deletedAt));
          expect(deserializedTask.isDeleted, equals(originalTask.isDeleted));
          expect(deserializedTask.recentDeleted, equals(originalTask.recentDeleted));
        }
      });
      
      test('Task state transitions maintain data integrity', () {
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
          
          // Test completion transition
          final completedTask = originalTask.markCompleted();
          expect(completedTask.status, equals(TaskStatus.completed));
          expect(completedTask.completedAt, isNotNull);
          expect(completedTask.id, equals(originalTask.id));
          expect(completedTask.title, equals(originalTask.title));
          expect(completedTask.priority, equals(originalTask.priority));
          
          // Test soft delete transition
          final deletedTask = originalTask.markSoftDeleted();
          expect(deletedTask.status, equals(TaskStatus.softDeleted));
          expect(deletedTask.isDeleted, isTrue);
          expect(deletedTask.recentDeleted, isTrue);
          expect(deletedTask.deletedAt, isNotNull);
          expect(deletedTask.id, equals(originalTask.id));
          expect(deletedTask.title, equals(originalTask.title));
          
          // Test restore transition
          final restoredTask = deletedTask.restore();
          expect(restoredTask.status, equals(TaskStatus.pending));
          expect(restoredTask.isDeleted, isFalse);
          expect(restoredTask.recentDeleted, isFalse);
          expect(restoredTask.deletedAt, isNull);
          expect(restoredTask.id, equals(originalTask.id));
          expect(restoredTask.title, equals(originalTask.title));
        }
      });
    });
    
    group('Unit Tests', () {
      test('Task creation with minimal data', () {
        final task = Task.create(
          title: 'Test Task',
          priority: TaskPriority.medium,
        );
        
        expect(task.title, equals('Test Task'));
        expect(task.priority, equals(TaskPriority.medium));
        expect(task.reason, isNull);
        expect(task.deadline, isNull);
        expect(task.status, equals(TaskStatus.pending));
        expect(task.isDeleted, isFalse);
      });
      
      test('Task creation with all data', () {
        final deadline = DateTime.now().add(const Duration(days: 1));
        final task = Task.create(
          title: 'Complete Project',
          priority: TaskPriority.high,
          reason: 'Important deadline',
          deadline: deadline,
        );
        
        expect(task.title, equals('Complete Project'));
        expect(task.priority, equals(TaskPriority.high));
        expect(task.reason, equals('Important deadline'));
        expect(task.deadline, equals(deadline));
      });
      
      test('Task deadline approaching detection', () {
        final now = DateTime.now();
        
        // Task with deadline in 12 hours (should be approaching)
        final approachingTask = Task.create(
          title: 'Approaching Task',
          priority: TaskPriority.medium,
          deadline: now.add(const Duration(hours: 12)),
        );
        expect(approachingTask.hasDeadlineApproaching(), isTrue);
        
        // Task with deadline in 2 days (should not be approaching)
        final futureTask = Task.create(
          title: 'Future Task',
          priority: TaskPriority.medium,
          deadline: now.add(const Duration(days: 2)),
        );
        expect(futureTask.hasDeadlineApproaching(), isFalse);
        
        // Task with no deadline
        final noDeadlineTask = Task.create(
          title: 'No Deadline Task',
          priority: TaskPriority.medium,
        );
        expect(noDeadlineTask.hasDeadlineApproaching(), isFalse);
      });
      
      test('Task overdue detection', () {
        final now = DateTime.now();
        
        // Overdue task
        final overdueTask = Task.create(
          title: 'Overdue Task',
          priority: TaskPriority.medium,
          deadline: now.subtract(const Duration(hours: 1)),
        );
        expect(overdueTask.isOverdue, isTrue);
        
        // Future task
        final futureTask = Task.create(
          title: 'Future Task',
          priority: TaskPriority.medium,
          deadline: now.add(const Duration(hours: 1)),
        );
        expect(futureTask.isOverdue, isFalse);
        
        // Completed overdue task (should not be considered overdue)
        final completedTask = overdueTask.markCompleted();
        expect(completedTask.isOverdue, isFalse);
      });
      
      test('Task auto cleanup detection', () {
        final now = DateTime.now();
        
        // Create a task and soft delete it
        final task = Task.create(
          title: 'Test Task',
          priority: TaskPriority.medium,
        );
        final deletedTask = task.markSoftDeleted();
        
        // Simulate task deleted 8 days ago
        final oldDeletedTask = deletedTask.copyWith(
          deletedAt: now.subtract(const Duration(days: 8)),
        );
        expect(oldDeletedTask.shouldAutoCleanup(), isTrue);
        
        // Recently deleted task (should not be cleaned up)
        expect(deletedTask.shouldAutoCleanup(), isFalse);
        
        // Non-deleted task
        expect(task.shouldAutoCleanup(), isFalse);
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
  ];
  
  const priorities = TaskPriority.values;
  
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