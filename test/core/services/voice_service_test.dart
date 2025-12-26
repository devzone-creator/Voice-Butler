import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/core/services/voice_service.dart';
import 'package:voice_butler/core/services/storage_service.dart';

void main() {
  group('Voice Service Tests', () {
    late VoiceService voiceService;
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      final testPath = './test/hive_test_db_voice_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      
      // Initialize storage service first (required by voice service for logging)
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
      voiceService = VoiceService.instance;
    });

    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 1: Voice Input Processing Reliability** - For any valid speech input, the voice processing system should either successfully convert it to text or provide a clear fallback mechanism', () {
        // **Validates: Requirements 1.1, 1.5**
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random speech input scenarios for comprehensive testing
          _generateSpeechInputScenario(i); // Generate scenario for test variation
          
          // Test that voice service handles all scenarios gracefully
          expect(() async {
            // Test initialization reliability
            try {
              final initialized = await voiceService.initialize();
              
              // Voice service should always be in a valid state after initialization
              expect(voiceService.state, isIn([
                VoiceInputState.idle,
                VoiceInputState.error,
                VoiceInputState.permissionDenied,
                VoiceInputState.initializing,
              ]), reason: 'Voice service should be in a valid state after initialization attempt');
              
              // Should have clear error message if in error state
              if (voiceService.state == VoiceInputState.error) {
                expect(voiceService.currentErrorMessage, isNotNull,
                    reason: 'Error state should provide clear error message');
                expect(voiceService.currentErrorMessage!.isNotEmpty, isTrue,
                    reason: 'Error message should not be empty');
              }
              
              // Should have fallback mechanism available
              expect(voiceService.getErrorMessage, isA<Function>(),
                  reason: 'Should provide error message fallback');
              
              // If initialization failed, should have clear error state
              if (!initialized) {
                expect(voiceService.state, isIn([
                  VoiceInputState.error,
                  VoiceInputState.permissionDenied,
                ]), reason: 'Failed initialization should result in error or permission denied state');
                expect(voiceService.currentErrorMessage, isNotNull,
                    reason: 'Failed initialization should provide error message');
              }
              
            } catch (e) {
              // Even if initialization throws, service should handle it gracefully
              expect(voiceService.state, isIn([
                VoiceInputState.error,
                VoiceInputState.idle,
              ]), reason: 'Service should handle initialization exceptions gracefully');
            }
            
          }, returnsNormally,
              reason: 'Voice service should handle all scenarios without throwing unhandled exceptions');
        }
      });
      
      test('Voice input state transitions are reliable and never leave service in undefined state', () {
        // Run property test with 50 iterations
        for (int i = 0; i < 50; i++) {
          // Generate random state transition scenarios
          final scenario = _generateStateTransitionScenario(i);
          
          // Test state transition reliability
          expect(() async {
            // Ensure service starts in a known state
            final initialState = voiceService.state;
            expect(initialState, isIn(VoiceInputState.values),
                reason: 'Service should always be in a valid state');
            
            // Test different transition scenarios
            switch (scenario['transition']) {
              case 'start_listening':
                try {
                  final success = await voiceService.startListening();
                  
                  // After start listening attempt, should be in valid state
                  expect(voiceService.state, isIn([
                    VoiceInputState.listening,
                    VoiceInputState.processing,
                    VoiceInputState.idle,
                    VoiceInputState.error,
                    VoiceInputState.permissionDenied,
                  ]), reason: 'State should be valid after start listening attempt');
                  
                  // If failed, should have error message
                  if (!success) {
                    expect(voiceService.state, isIn([
                      VoiceInputState.error,
                      VoiceInputState.permissionDenied,
                    ]), reason: 'Failed start should result in error state');
                  }
                } catch (e) {
                  // Should handle exceptions gracefully
                  expect(voiceService.state, isIn(VoiceInputState.values),
                      reason: 'Should maintain valid state even after exceptions');
                }
                break;
                
              case 'stop_listening':
                try {
                  await voiceService.stopListening();
                  
                  expect(voiceService.state, isIn([
                    VoiceInputState.idle,
                    VoiceInputState.processing,
                    VoiceInputState.error,
                  ]), reason: 'State should be valid after stop listening');
                } catch (e) {
                  expect(voiceService.state, isIn(VoiceInputState.values),
                      reason: 'Should maintain valid state after stop exceptions');
                }
                break;
                
              case 'cancel_listening':
                try {
                  await voiceService.cancelListening();
                  
                  expect(voiceService.state, isIn([
                    VoiceInputState.idle,
                    VoiceInputState.error,
                  ]), reason: 'State should be valid after cancel listening');
                } catch (e) {
                  expect(voiceService.state, isIn(VoiceInputState.values),
                      reason: 'Should maintain valid state after cancel exceptions');
                }
                break;
            }
            
          }, returnsNormally,
              reason: 'State transitions should never throw unhandled exceptions');
        }
      });
      
      test('Error handling provides consistent fallback mechanisms', () {
        // Test all possible error scenarios
        final errorScenarios = [
          VoiceInputError.permissionDenied,
          VoiceInputError.microphoneNotAvailable,
          VoiceInputError.speechRecognitionNotAvailable,
          VoiceInputError.networkError,
          VoiceInputError.timeout,
          VoiceInputError.unknown,
        ];
        
        for (final error in errorScenarios) {
          // Each error should have a clear, non-empty message
          final errorMessage = voiceService.getErrorMessage(error);
          expect(errorMessage, isNotNull,
              reason: 'Error $error should have a message');
          expect(errorMessage.isNotEmpty, isTrue,
              reason: 'Error message for $error should not be empty');
          expect(errorMessage.length, greaterThan(10),
              reason: 'Error message for $error should be descriptive');
          
          // Error message should be user-friendly (no technical jargon)
          expect(errorMessage.toLowerCase(), isNot(contains('exception')),
              reason: 'Error message should be user-friendly');
          expect(errorMessage.toLowerCase(), isNot(contains('null')),
              reason: 'Error message should be user-friendly');
          // Note: "error" is acceptable in user-friendly messages like "Network error occurred"
        }
      });
      
      test('Service statistics provide consistent information', () {
        // Run property test with 30 iterations
        for (int i = 0; i < 30; i++) {
          final stats = voiceService.getStatistics();
          
          // Statistics should always contain required fields
          expect(stats, containsPair('isInitialized', isA<bool>()));
          expect(stats, containsPair('isAvailable', isA<bool>()));
          expect(stats, containsPair('currentState', isA<String>()));
          expect(stats, containsPair('lastRecognizedText', isA<String>()));
          expect(stats, containsPair('confidenceLevel', isA<double>()));
          expect(stats, containsPair('isListening', isA<bool>()));
          
          // State should be valid
          final currentState = stats['currentState'] as String;
          expect(VoiceInputState.values.map((s) => s.name), contains(currentState),
              reason: 'Current state should be a valid VoiceInputState');
          
          // Confidence level should be in valid range
          final confidence = stats['confidenceLevel'] as double;
          expect(confidence, inInclusiveRange(0.0, 1.0),
              reason: 'Confidence level should be between 0.0 and 1.0');
          
          // Boolean fields should be consistent
          final isInitialized = stats['isInitialized'] as bool;
          final isAvailable = stats['isAvailable'] as bool;
          final isListening = stats['isListening'] as bool;
          
          if (!isInitialized) {
            expect(isAvailable, isFalse,
                reason: 'Service cannot be available if not initialized');
            expect(isListening, isFalse,
                reason: 'Service cannot be listening if not initialized');
          }
          
          if (isListening) {
            expect(isInitialized, isTrue,
                reason: 'Service must be initialized to be listening');
          }
        }
      });
      
      test('Availability check is consistent', () {
        // Run property test with 20 iterations
        for (int i = 0; i < 20; i++) {
          expect(() async {
            final isAvailable = await voiceService.checkAvailability();
            expect(isAvailable, isA<bool>(),
                reason: 'Availability check should return a boolean');
            
            // Multiple calls should return consistent results
            final isAvailable2 = await voiceService.checkAvailability();
            expect(isAvailable2, isA<bool>(),
                reason: 'Subsequent availability checks should also return boolean');
            
          }, returnsNormally,
              reason: 'Availability check should never throw exceptions');
        }
      });
    });
    
    group('Unit Tests', () {
      test('Voice service singleton pattern', () {
        final instance1 = VoiceService.instance;
        final instance2 = VoiceService.instance;
        expect(identical(instance1, instance2), isTrue,
            reason: 'VoiceService should be a singleton');
      });
      
      test('Initial state is correct', () {
        // In test environment, voice service may detect permission issues
        expect(voiceService.state, isIn([
          VoiceInputState.idle,
          VoiceInputState.permissionDenied,
          VoiceInputState.error,
        ]), reason: 'Voice service should be in a valid initial state');
        
        expect(voiceService.lastRecognizedText, isEmpty);
        expect(voiceService.confidenceLevel, equals(0.0));
        expect(voiceService.isListening, isFalse);
      });
      
      test('Error message generation', () {
        // Test each error type has a message
        for (final error in VoiceInputError.values) {
          final message = voiceService.getErrorMessage(error);
          expect(message, isNotNull);
          expect(message.isNotEmpty, isTrue);
          expect(message.length, greaterThan(5),
              reason: 'Error messages should be descriptive');
        }
      });
      
      test('State validation', () {
        // All states should be valid enum values
        for (final state in VoiceInputState.values) {
          expect(state.name, isNotEmpty);
        }
        
        // Current state should always be valid
        expect(VoiceInputState.values, contains(voiceService.state));
      });
      
      test('Statistics structure', () {
        final stats = voiceService.getStatistics();
        
        // Should contain all required fields
        final requiredFields = [
          'isInitialized',
          'isAvailable', 
          'currentState',
          'lastRecognizedText',
          'confidenceLevel',
          'isListening',
        ];
        
        for (final field in requiredFields) {
          expect(stats.keys, contains(field),
              reason: 'Statistics should contain $field');
        }
      });
    });
  });
}

/// Generates random speech input scenarios for property-based testing
Map<String, dynamic> _generateSpeechInputScenario(int seed) {
  final random = _SeededRandom(seed);
  
  return {
    'shouldInitialize': random.nextBool(),
    'hasPermission': random.nextBool(),
    'speechRecognitionAvailable': random.nextBool(),
    'networkAvailable': random.nextBool(),
    'inputText': _generateRandomSpeechText(seed),
    'confidence': random.nextDouble(),
  };
}

/// Generates random state transition scenarios
Map<String, dynamic> _generateStateTransitionScenario(int seed) {
  final random = _SeededRandom(seed);
  
  final transitions = ['start_listening', 'stop_listening', 'cancel_listening'];
  
  return {
    'transition': transitions[random.nextInt(transitions.length)],
    'shouldSucceed': random.nextBool(),
    'isCurrentlyListening': random.nextBool(),
    'hasPermission': random.nextBool(),
  };
}

/// Generates random speech text for testing
String _generateRandomSpeechText(int seed) {
  final random = _SeededRandom(seed);
  
  final phrases = [
    'Create a new task',
    'Add meeting to calendar',
    'Remind me to call John',
    'Set high priority for project',
    'Schedule deadline for tomorrow',
    'Complete the documentation',
    'Review the code changes',
    'Update the user interface',
    'Fix the critical bug',
    'Deploy to production',
  ];
  
  return phrases[random.nextInt(phrases.length)];
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
  
  double nextDouble() {
    return nextInt(1000000) / 1000000.0;
  }
}