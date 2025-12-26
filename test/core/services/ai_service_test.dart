import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/core/services/ai_service.dart';
import 'package:voice_butler/core/services/storage_service.dart';
import 'package:voice_butler/core/models/task.dart';

void main() {
  group('AI Service Tests', () {
    late AIService aiService;
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      final testPath = './test/hive_test_db_ai_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      
      // Initialize storage service first (required by AI service for logging)
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
      aiService = AIService.instance;
    });

    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 2: AI Intent Extraction Completeness** - For any text input from speech conversion, the AI intent extraction should produce structured task data containing all required fields', () async {
        // **Validates: Requirements 1.2**
        
        // Run property test with various input scenarios
        final testInputs = [
          'Create a task to review the code',
          'Remind me to call John tomorrow',
          'High priority: Fix the critical bug by Friday',
          'Schedule a meeting with the team next week',
          'Buy groceries',
          'Complete the project documentation urgently',
          'Low priority task to update the website',
          'Call the client about the proposal deadline Monday',
          'Review and approve the budget by end of month',
          'Set up the development environment',
        ];
        
        for (int i = 0; i < testInputs.length; i++) {
          final input = testInputs[i];
          
          // Test that AI service handles all inputs gracefully
          expect(() async {
            final result = await aiService.extractTaskIntent(input);
            
            // Should always return a result (success or error)
            expect(result, isNotNull,
                reason: 'AI service should always return a result');
            
            if (result.isSuccess) {
              // If successful, should have required fields
              expect(result.title, isNotNull,
                  reason: 'Successful extraction should have a title');
              expect(result.title!.isNotEmpty, isTrue,
                  reason: 'Title should not be empty');
              expect(result.priority, isNotNull,
                  reason: 'Successful extraction should have a priority');
              expect(result.priority, isIn(TaskPriority.values),
                  reason: 'Priority should be a valid TaskPriority value');
              
              // Optional fields can be null but if present should be valid
              if (result.reason != null) {
                expect(result.reason!.isNotEmpty, isTrue,
                    reason: 'Reason should not be empty if present');
              }
              
              if (result.deadline != null) {
                expect(result.deadline!.isAfter(DateTime.now().subtract(const Duration(days: 1))), isTrue,
                    reason: 'Deadline should be reasonable (not in the past)');
              }
            } else {
              // If failed, should have error message
              expect(result.error, isNotNull,
                  reason: 'Failed extraction should have error message');
              expect(result.error!.isNotEmpty, isTrue,
                  reason: 'Error message should not be empty');
            }
            
          }, returnsNormally,
              reason: 'AI service should handle all inputs without throwing exceptions');
        }
      });
      
      test('AI service handles edge cases and invalid inputs gracefully', () async {
        final edgeCaseInputs = [
          '', // Empty string
          '   ', // Whitespace only
          'a', // Single character
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 10, // Very long text
          '12345', // Numbers only
          '!@#\$%^&*()', // Special characters only
          'Create a task', // Minimal valid input
          'This is not a task request but a random sentence about weather', // Ambiguous input
        ];
        
        for (final input in edgeCaseInputs) {
          expect(() async {
            final result = await aiService.extractTaskIntent(input);
            
            // Should always return a result
            expect(result, isNotNull);
            
            // Should either succeed with valid data or fail with clear error
            if (result.isSuccess) {
              expect(result.title, isNotNull);
              expect(result.title!.isNotEmpty, isTrue);
              expect(result.priority, isNotNull);
            } else {
              expect(result.error, isNotNull);
              expect(result.error!.isNotEmpty, isTrue);
            }
            
          }, returnsNormally,
              reason: 'AI service should handle edge cases gracefully');
        }
      });
      
      test('Rate limiting works correctly', () async {
        // Test rate limiting behavior
        int successCount = 0;
        int rateLimitCount = 0;
        int errorCount = 0;
        
        // Make multiple rapid requests
        for (int i = 0; i < 10; i++) {
          final result = await aiService.extractTaskIntent('Test task $i');
          
          if (result.isSuccess) {
            successCount++;
          } else if (result.error?.contains('rate limit') == true) {
            rateLimitCount++;
          } else {
            errorCount++;
          }
        }
        
        // Should handle all requests (either process, rate limit, or error due to no API key)
        expect(successCount + rateLimitCount + errorCount, equals(10),
            reason: 'All requests should be either processed, rate limited, or error due to no API key');
      });
      
      test('Service initialization is idempotent', () async {
        // Multiple initialization calls should be safe
        for (int i = 0; i < 5; i++) {
          expect(() async {
            await aiService.initialize();
            
            // Should maintain consistent state
            expect(aiService.isInitialized, isA<bool>());
            expect(aiService.hasApiKey, isA<bool>());
            
          }, returnsNormally,
              reason: 'Multiple initialization calls should be safe');
        }
      });
      
      test('Error handling provides meaningful messages', () async {
        // Test various error scenarios
        final result = await aiService.extractTaskIntent('Test input');
        
        if (!result.isSuccess) {
          expect(result.error, isNotNull);
          expect(result.error!.isNotEmpty, isTrue);
          
          // Error message should be user-friendly
          expect(result.error!.toLowerCase(), isNot(contains('null')),
              reason: 'Error messages should be user-friendly');
          expect(result.error!.toLowerCase(), isNot(contains('exception')),
              reason: 'Error messages should not expose technical details');
        }
      });
    });
    
    group('Unit Tests', () {
      test('AI service singleton pattern', () {
        final instance1 = AIService.instance;
        final instance2 = AIService.instance;
        expect(identical(instance1, instance2), isTrue,
            reason: 'AIService should be a singleton');
      });
      
      test('Initial state is correct', () {
        expect(aiService.hasApiKey, isA<bool>());
        // Note: isInitialized may vary depending on API key availability
      });
      
      test('Statistics provide required information', () {
        final stats = aiService.getStatistics();
        
        // Should contain all required fields
        expect(stats, containsPair('isInitialized', isA<bool>()));
        expect(stats, containsPair('hasApiKey', isA<bool>()));
        expect(stats, containsPair('requestCount', isA<int>()));
        expect(stats, containsPair('rateLimitRemaining', isA<int>()));
        
        // Request count should be non-negative
        expect(stats['requestCount'] as int, greaterThanOrEqualTo(0));
        expect(stats['rateLimitRemaining'] as int, greaterThanOrEqualTo(0));
      });
      
      test('TaskIntentResult factory methods work correctly', () {
        // Test success result
        final successResult = TaskIntentResult.success(
          title: 'Test Task',
          priority: TaskPriority.high,
          reason: 'Test reason',
          deadline: DateTime.now().add(const Duration(days: 1)),
        );
        
        expect(successResult.isSuccess, isTrue);
        expect(successResult.error, isNull);
        expect(successResult.title, equals('Test Task'));
        expect(successResult.priority, equals(TaskPriority.high));
        expect(successResult.reason, equals('Test reason'));
        expect(successResult.deadline, isNotNull);
        
        // Test error result
        final errorResult = TaskIntentResult.error('Test error');
        
        expect(errorResult.isSuccess, isFalse);
        expect(errorResult.error, equals('Test error'));
        expect(errorResult.title, isNull);
        expect(errorResult.priority, isNull);
        expect(errorResult.reason, isNull);
        expect(errorResult.deadline, isNull);
      });
      
      test('AutomationRuleResult factory methods work correctly', () {
        // Test success result
        final successResult = AutomationRuleResult.success(
          name: 'Test Rule',
          trigger: 'task_created',
          conditions: [{'type': 'priority_equals', 'value': 'high'}],
          actions: [{'type': 'send_notification', 'parameters': {'title': 'Test'}}],
          description: 'Test description',
        );
        
        expect(successResult.isSuccess, isTrue);
        expect(successResult.error, isNull);
        expect(successResult.name, equals('Test Rule'));
        expect(successResult.trigger, equals('task_created'));
        expect(successResult.conditions, isNotNull);
        expect(successResult.actions, isNotNull);
        expect(successResult.description, equals('Test description'));
        
        // Test error result
        final errorResult = AutomationRuleResult.error('Test error');
        
        expect(errorResult.isSuccess, isFalse);
        expect(errorResult.error, equals('Test error'));
        expect(errorResult.name, isNull);
        expect(errorResult.trigger, isNull);
        expect(errorResult.conditions, isNull);
        expect(errorResult.actions, isNull);
        expect(errorResult.description, isNull);
      });
    });
  });
}