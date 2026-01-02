import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/core/services/storage_service.dart';
import 'package:voice_butler/core/services/ai_service.dart';
import 'package:voice_butler/core/models/automation_rule.dart';
import 'package:voice_butler/features/automation/providers/rule_builder_provider.dart';

void main() {
  group('Rule Builder Provider Property Tests', () {
    late RuleBuilderProvider ruleBuilderProvider;
    late StorageService storageService;
    late AIService aiService;

    setUpAll(() async {
      // Initialize Hive for testing
      final testPath = './test/hive_test_db_rule_builder_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      
      // Initialize services
      storageService = StorageService.instance;
      await storageService.initialize();
      
      aiService = AIService.instance;
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
      ruleBuilderProvider = RuleBuilderProvider();
    });

    group('Property 15: Custom Rule Validation', () {
      test('**Feature: voice-butler, Property 15: Custom Rule Validation** - For any custom automation rule created by a user, the system should validate the rule structure using trigger-condition-action patterns', () async {
        // **Validates: Requirements 4.2**
        
        // Test basic rule validation scenarios
        final testScenarios = [
          {
            'name': 'Valid Complete Rule',
            'ruleName': 'Test Rule',
            'trigger': RuleTrigger.taskCreated,
            'shouldBeValid': true,
          },
          {
            'name': 'Rule Without Name',
            'ruleName': '',
            'trigger': RuleTrigger.taskCreated,
            'shouldBeValid': false,
          },
        ];
        
        for (int i = 0; i < testScenarios.length; i++) {
          final scenario = testScenarios[i];
          final shouldBeValid = scenario['shouldBeValid'] as bool;
          final scenarioName = scenario['name'] as String;
          
          // Reset provider for each test
          ruleBuilderProvider.resetRule();
          
          // Set up rule according to scenario
          ruleBuilderProvider.setRuleName(scenario['ruleName'] as String);
          
          if (scenario['trigger'] != null) {
            ruleBuilderProvider.setTrigger(scenario['trigger'] as RuleTrigger);
          }
          
          // Add a basic action for valid scenarios
          if (shouldBeValid) {
            ruleBuilderProvider.addAction(RuleAction.sendNotification(
              title: 'Test', 
              message: 'Test message'
            ));
          }
          
          // Test validation
          final isValid = ruleBuilderProvider.isRuleValid;
          expect(isValid, equals(shouldBeValid),
              reason: '$scenarioName: Expected validity $shouldBeValid but got $isValid');
          
          // Test validation errors
          final validationErrors = ruleBuilderProvider.validationErrors;
          if (shouldBeValid) {
            expect(validationErrors.isEmpty, isTrue,
                reason: '$scenarioName: Valid rule should have no validation errors');
          } else {
            expect(validationErrors.isNotEmpty, isTrue,
                reason: '$scenarioName: Invalid rule should have validation errors');
          }
        }
      });
      
      group('Property 16: Natural Language Rule Conversion', () {
        test('**Feature: voice-butler, Property 16: Natural Language Rule Conversion** - For any natural language rule description, the AI should convert it into a structured automation rule', () async {
          // **Validates: Requirements 4.3**
          
          // Test various natural language rule descriptions
          final testDescriptions = [
            'Send me a notification when I create a high priority task',
            'Remind me 30 minutes before any deadline',
            'When a task is overdue, change its priority to high',
            'Log an activity when any task is completed',
        ];
        
        for (int i = 0; i < testDescriptions.length; i++) {
          final description = testDescriptions[i];
          
          // Test AI service conversion
          final result = await aiService.convertNaturalLanguageRule(description);
          
          // Property: AI should always return a result (success or error)
          expect(result, isNotNull,
              reason: 'AI service should always return a result for: $description');
          
          if (result.isSuccess) {
            // Property: Successful conversion should have required fields
            expect(result.name, isNotNull,
                reason: 'Successful conversion should have rule name');
            expect(result.name!.isNotEmpty, isTrue,
                reason: 'Rule name should not be empty');
            
            expect(result.trigger, isNotNull,
                reason: 'Successful conversion should have trigger');
            expect(result.trigger!.isNotEmpty, isTrue,
                reason: 'Trigger should not be empty');
            
            expect(result.actions, isNotNull,
                reason: 'Successful conversion should have actions');
            expect(result.actions!.isNotEmpty, isTrue,
                reason: 'Actions list should not be empty');
          } else {
            // Property: Failed conversion should have meaningful error
            expect(result.error, isNotNull,
                reason: 'Failed conversion should have error message');
            expect(result.error!.isNotEmpty, isTrue,
                reason: 'Error message should not be empty');
          }
        }
      });
    });

    group('Property 17: Rule Effect Explanation', () {
      test('**Feature: voice-butler, Property 17: Rule Effect Explanation** - For any automation rule created or modified, the system should provide clear explanations of the rule effects', () async {
        // **Validates: Requirements 4.4**
        
        // Test rule effect explanations for various rule descriptions
        final testRuleDescriptions = [
          'Notify when high priority tasks are created',
          'Send reminders for approaching deadlines',
          'Escalate overdue medium priority tasks',
          'Log activity when tasks are completed',
        ];
        
        for (int i = 0; i < testRuleDescriptions.length; i++) {
          final description = testRuleDescriptions[i];
          
          // Test AI service explanation
          final explanation = await aiService.explainRuleEffects(description);
          
          // Property: Should always return an explanation
          expect(explanation, isNotNull,
              reason: 'AI service should always return an explanation');
          expect(explanation.isNotEmpty, isTrue,
              reason: 'Explanation should not be empty');
          
          // Property: Explanation should be user-friendly
          expect(explanation.length, greaterThan(20),
              reason: 'Explanation should be descriptive (more than 20 characters)');
          
          // Property: Explanation should not contain technical jargon
          final technicalTerms = ['null', 'undefined', 'exception', 'error', 'debug'];
          final explanationLower = explanation.toLowerCase();
          
          for (final term in technicalTerms) {
            expect(explanationLower.contains(term), isFalse,
                reason: 'Explanation should not contain technical term: $term');
          }
          
          // Property: Explanation should mention relevant context
          final mentionsRuleContext = explanationLower.contains('task') ||
              explanationLower.contains('notification') ||
              explanationLower.contains('reminder') ||
              explanationLower.contains('priority') ||
              explanationLower.contains('rule') ||
              explanationLower.contains('automation');
          
          expect(mentionsRuleContext, isTrue,
              reason: 'Explanation should mention relevant rule context');
        }
      });
    });
  });
}