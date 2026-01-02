import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/features/ai/providers/ai_provider.dart';
import 'package:voice_butler/core/services/storage_service.dart';
import 'package:voice_butler/core/models/task.dart';

void main() {
  group('AI Provider Tests', () {
    late AIProvider aiProvider;
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      final testPath = './test/hive_test_db_ai_provider_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      
      // Initialize storage service first
      storageService = StorageService.instance;
      await storageService.initialize();
    });

    tearDownAll(() async {
      try {
        await storageService.close();
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    setUp(() {
      aiProvider = AIProvider();
    });

    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 3: Task Preview Accuracy** - Task creation from intent preserves all extracted data fields', () async {
        // **Validates: Requirements 1.3**
        
        // Test fallback parsing (which is always available) to ensure task preview accuracy
        final testInputs = [
          'Create a high priority task to review code',
          'Urgent: Fix the critical bug',
          'Low priority task to update documentation',
          'Remind me to call John today',
          'Schedule meeting with team tomorrow',
          'Buy groceries when possible',
          'Complete project by next week',
          'Update website eventually',
          'Critical task: Deploy to production',
          'Review and approve budget next month',
        ];
        
        for (int i = 0; i < testInputs.length; i++) {
          final input = testInputs[i];
          
          // Use fallback parsing to get consistent results
          final result = aiProvider.fallbackTaskExtraction(input);
          
          // Should always succeed with fallback parsing
          expect(result.isSuccess, isTrue,
              reason: 'Fallback parsing should always succeed for valid input');
          
          // Verify all required fields are present
          expect(result.title, isNotNull,
              reason: 'Intent extraction should produce a title');
          expect(result.title!.isNotEmpty, isTrue,
              reason: 'Extracted title should not be empty');
          expect(result.priority, isNotNull,
              reason: 'Intent extraction should produce a priority');
          expect(result.priority, isIn(TaskPriority.values),
              reason: 'Extracted priority should be valid');
          
          // Create task from intent (simulating task preview)
          final previewTask = aiProvider.createTaskFromIntent();
          
          expect(previewTask, isNotNull,
              reason: 'Should be able to create task from successful intent');
          
          // Verify task preview contains all extracted data exactly
          expect(previewTask!.title, equals(result.title),
              reason: 'Task preview title should match extracted title exactly');
          expect(previewTask.priority, equals(result.priority),
              reason: 'Task preview priority should match extracted priority exactly');
          expect(previewTask.reason, equals(result.reason),
              reason: 'Task preview reason should match extracted reason exactly');
          expect(previewTask.deadline, equals(result.deadline),
              reason: 'Task preview deadline should match extracted deadline exactly');
          
          // Verify task has proper structure for preview
          expect(previewTask.id, isNotEmpty,
              reason: 'Task preview should have generated ID');
          expect(previewTask.status, equals(TaskStatus.pending),
              reason: 'Task preview should have pending status');
          expect(previewTask.createdAt, isNotNull,
              reason: 'Task preview should have creation timestamp');
          expect(previewTask.isDeleted, isFalse,
              reason: 'Task preview should not be deleted');
          expect(previewTask.recentDeleted, isFalse,
              reason: 'Task preview should not be in recent deleted');
          
          // Verify timestamp is recent (within last second)
          final now = DateTime.now();
          final timeDiff = now.difference(previewTask.createdAt).inMilliseconds;
          expect(timeDiff, lessThan(1000),
              reason: 'Task preview creation timestamp should be recent');
        }
      });
      
      test('Task preview handles optional fields correctly', () async {
        // Test scenarios with different combinations of optional fields
        final scenarios = [
          {
            'input': 'Simple task',
            'expectReason': false,
            'expectDeadline': false,
          },
          {
            'input': 'Task with reason because it\'s important',
            'expectReason': true,
            'expectDeadline': false,
          },
          {
            'input': 'Task due today',
            'expectReason': false,
            'expectDeadline': true,
          },
          {
            'input': 'Important task due tomorrow because client needs it',
            'expectReason': true,
            'expectDeadline': true,
          },
        ];
        
        for (final scenario in scenarios) {
          final input = scenario['input'] as String;
          final expectReason = scenario['expectReason'] as bool;
          final expectDeadline = scenario['expectDeadline'] as bool;
          
          final result = aiProvider.fallbackTaskExtraction(input);
          expect(result.isSuccess, isTrue);
          
          final previewTask = aiProvider.createTaskFromIntent();
          expect(previewTask, isNotNull);
          
          // Check optional fields match expectations
          if (expectReason) {
            expect(previewTask!.reason, isNotNull,
                reason: 'Task preview should include reason when extracted');
            expect(previewTask.reason!.isNotEmpty, isTrue,
                reason: 'Task preview reason should not be empty');
          }
          
          if (expectDeadline) {
            expect(previewTask!.deadline, isNotNull,
                reason: 'Task preview should include deadline when extracted');
            expect(previewTask.deadline!.isAfter(DateTime.now().subtract(const Duration(minutes: 1))), isTrue,
                reason: 'Task preview deadline should be reasonable');
          }
        }
      });
      
      test('Task preview consistency across multiple extractions', () async {
        // Test that the same input produces consistent preview data
        const testInput = 'High priority task to review code by tomorrow';
        
        for (int i = 0; i < 5; i++) {
          final result1 = aiProvider.fallbackTaskExtraction(testInput);
          final result2 = aiProvider.fallbackTaskExtraction(testInput);
          
          expect(result1.isSuccess, isTrue);
          expect(result2.isSuccess, isTrue);
          
          // Results should be consistent (excluding timestamps and IDs)
          expect(result1.title, equals(result2.title),
              reason: 'Same input should produce consistent title');
          expect(result1.priority, equals(result2.priority),
              reason: 'Same input should produce consistent priority');
          expect(result1.reason, equals(result2.reason),
              reason: 'Same input should produce consistent reason');
          
          // Deadlines should be consistent (within same day for "tomorrow")
          if (result1.deadline != null && result2.deadline != null) {
            final diff = result1.deadline!.difference(result2.deadline!).inHours.abs();
            expect(diff, lessThan(24),
                reason: 'Same input should produce consistent deadline');
          }
        }
      });
    });
    
    group('Unit Tests', () {
      test('AI provider initialization', () {
        expect(aiProvider.isProcessing, isFalse);
        expect(aiProvider.lastError, isNull);
        expect(aiProvider.lastTaskResult, isNull);
        expect(aiProvider.lastRuleResult, isNull);
      });
      
      test('Fallback parsing handles edge cases', () {
        final edgeCases = [
          '',
          '   ',
          'a',
          'Create a task to',
          'Remind me to',
          'TODO:',
        ];
        
        for (final input in edgeCases) {
          expect(() {
            final result = aiProvider.fallbackTaskExtraction(input);
            
            if (input.trim().isEmpty) {
              expect(result.isSuccess, isFalse);
              expect(result.error, isNotNull);
            } else {
              expect(result.isSuccess, isTrue);
              expect(result.title, isNotNull);
              expect(result.title!.isNotEmpty, isTrue);
            }
          }, returnsNormally,
              reason: 'Fallback parsing should handle edge cases gracefully');
        }
      });
      
      test('Priority detection works correctly', () {
        final priorityTests = [
          {'input': 'urgent task', 'expected': TaskPriority.high},
          {'input': 'critical issue', 'expected': TaskPriority.high},
          {'input': 'high priority task', 'expected': TaskPriority.high},
          {'input': 'low priority task', 'expected': TaskPriority.low},
          {'input': 'when possible', 'expected': TaskPriority.low},
          {'input': 'eventually do this', 'expected': TaskPriority.low},
          {'input': 'regular task', 'expected': TaskPriority.medium},
        ];
        
        for (final test in priorityTests) {
          final result = aiProvider.fallbackTaskExtraction(test['input'] as String);
          expect(result.isSuccess, isTrue);
          expect(result.priority, equals(test['expected'] as TaskPriority));
        }
      });
    });
  });
}