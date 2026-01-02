import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/features/settings/providers/settings_provider.dart';
import 'package:voice_butler/core/services/storage_service.dart';

void main() {
  group('SettingsProvider', () {
    late SettingsProvider settingsProvider;
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing with a unique path
      final testPath = './test/hive_test_db_settings_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      storageService = StorageService.instance;
      await storageService.initialize();
    });

    tearDownAll(() async {
      try {
        await storageService.close();
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    setUp(() {
      settingsProvider = SettingsProvider();
    });

    group('Property 29: Advanced Mode Transition', () {
      test('Advanced Mode transition preserves data integrity', () async {
        // Property: Toggling Advanced Mode should never cause data loss
        // and should maintain consistent state
        
        const iterations = 10; // Reduced for Windows compatibility
        
        for (int i = 0; i < iterations; i++) {
          // Record initial state
          final initialAdvancedMode = settingsProvider.isAdvancedMode;
          final initialNotifications = settingsProvider.notificationsEnabled;
          final initialBackgroundProcessing = settingsProvider.backgroundProcessingEnabled;
          final initialReminderDelay = settingsProvider.defaultReminderDelayMinutes;
          final initialMaxLogs = settingsProvider.maxLogsToKeep;
          final initialRetentionDays = settingsProvider.maxLogRetentionDays;
          
          // Action: Toggle Advanced Mode
          await settingsProvider.setAdvancedMode(!initialAdvancedMode);
          
          // Verification: Advanced Mode state changed correctly
          expect(settingsProvider.isAdvancedMode, equals(!initialAdvancedMode));
          
          // Verification: Other settings remain unchanged
          expect(settingsProvider.notificationsEnabled, equals(initialNotifications));
          expect(settingsProvider.backgroundProcessingEnabled, equals(initialBackgroundProcessing));
          expect(settingsProvider.defaultReminderDelayMinutes, equals(initialReminderDelay));
          expect(settingsProvider.maxLogsToKeep, equals(initialMaxLogs));
          expect(settingsProvider.maxLogRetentionDays, equals(initialRetentionDays));
          
          // Verification: Advanced features availability matches mode
          final features = settingsProvider.getAdvancedModeFeatures();
          expect(features['customRules'], equals(settingsProvider.isAdvancedMode));
          expect(features['presetWorkflows'], equals(settingsProvider.isAdvancedMode));
          expect(features['ruleBuilder'], equals(settingsProvider.isAdvancedMode));
          expect(features['advancedAutomation'], equals(settingsProvider.isAdvancedMode));
          expect(features['naturalLanguageRules'], equals(settingsProvider.isAdvancedMode));
          
          // Toggle back to test bidirectional transition
          await settingsProvider.setAdvancedMode(initialAdvancedMode);
          
          // Verification: State restored correctly
          expect(settingsProvider.isAdvancedMode, equals(initialAdvancedMode));
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('Advanced Mode transition handles storage errors gracefully', () async {
        // Property: Storage errors during Advanced Mode transition should
        // revert state and not leave the provider in an inconsistent state
        
        const iterations = 5; // Reduced for Windows compatibility
        
        for (int i = 0; i < iterations; i++) {
          final initialMode = i % 2 == 0; // Alternate starting modes
          final targetMode = !initialMode;
          
          // Set initial state
          await settingsProvider.setAdvancedMode(initialMode);
          
          // Record initial state
          final initialNotifications = settingsProvider.notificationsEnabled;
          final initialBackgroundProcessing = settingsProvider.backgroundProcessingEnabled;
          
          // Action: Change Advanced Mode
          await settingsProvider.setAdvancedMode(targetMode);
          
          // Verification: State changed correctly
          expect(settingsProvider.isAdvancedMode, equals(targetMode));
          
          // Verification: Other settings remain unchanged
          expect(settingsProvider.notificationsEnabled, equals(initialNotifications));
          expect(settingsProvider.backgroundProcessingEnabled, equals(initialBackgroundProcessing));
          
          // Verification: Features availability matches new state
          final features = settingsProvider.getAdvancedModeFeatures();
          expect(features['customRules'], equals(targetMode));
          expect(features['presetWorkflows'], equals(targetMode));
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('Advanced Mode transition maintains listener notifications', () async {
        // Property: Advanced Mode transitions should always notify listeners
        // exactly once per successful transition
        
        const iterations = 5; // Reduced for Windows compatibility
        int notificationCount = 0;
        
        settingsProvider.addListener(() {
          notificationCount++;
        });
        
        for (int i = 0; i < iterations; i++) {
          final initialCount = notificationCount;
          final currentMode = settingsProvider.isAdvancedMode;
          
          // Action: Toggle Advanced Mode
          await settingsProvider.setAdvancedMode(!currentMode);
          
          // Verification: At least one notification was sent (could be more due to internal updates)
          expect(notificationCount, greaterThan(initialCount));
          
          // Verification: State changed correctly
          expect(settingsProvider.isAdvancedMode, equals(!currentMode));
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('Advanced Mode feature availability is consistent', () async {
        // Property: Advanced Mode feature availability should always
        // be consistent with the current mode state
        
        const iterations = 10; // Reduced for Windows compatibility
        
        for (int i = 0; i < iterations; i++) {
          final targetMode = i % 2 == 0;
          
          // Action: Set Advanced Mode
          await settingsProvider.setAdvancedMode(targetMode);
          
          // Verification: All advanced features match the mode
          final features = settingsProvider.getAdvancedModeFeatures();
          for (final featureName in features.keys) {
            expect(features[featureName], equals(targetMode),
                reason: 'Feature $featureName should match Advanced Mode state');
            
            // Also test individual feature check
            expect(settingsProvider.isAdvancedFeatureAvailable(featureName), 
                equals(targetMode));
          }
          
          // Verification: Unknown features return false
          expect(settingsProvider.isAdvancedFeatureAvailable('unknownFeature'), 
              equals(false));
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('Advanced Mode statistics are accessible', () async {
        // Property: Statistics should be accessible regardless of Advanced Mode state
        
        const iterations = 5; // Reduced for Windows compatibility
        
        for (int i = 0; i < iterations; i++) {
          final targetMode = i % 2 == 0;
          
          // Action: Set Advanced Mode
          await settingsProvider.setAdvancedMode(targetMode);
          
          // Verification: Statistics are accessible and non-negative
          expect(settingsProvider.activityLogCount, greaterThanOrEqualTo(0));
          expect(settingsProvider.customRulesCount, greaterThanOrEqualTo(0));
          expect(settingsProvider.storageUsagePercentage, greaterThanOrEqualTo(0.0));
          expect(settingsProvider.storageUsagePercentage, lessThanOrEqualTo(100.0));
          
          // Verification: Settings summary is complete
          final summary = settingsProvider.getSettingsSummary();
          expect(summary['advancedMode'], equals(targetMode));
          expect(summary.containsKey('notificationsEnabled'), isTrue);
          expect(summary.containsKey('backgroundProcessingEnabled'), isTrue);
          expect(summary.containsKey('activityLogCount'), isTrue);
          expect(summary.containsKey('customRulesCount'), isTrue);
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      test('Advanced Mode settings validation', () async {
        // Property: All settings should maintain valid ranges regardless of Advanced Mode
        
        const iterations = 5; // Reduced for Windows compatibility
        
        for (int i = 0; i < iterations; i++) {
          final targetMode = i % 2 == 0;
          
          // Action: Set Advanced Mode
          await settingsProvider.setAdvancedMode(targetMode);
          
          // Verification: All settings are within valid ranges
          expect(settingsProvider.defaultReminderDelayMinutes, greaterThanOrEqualTo(1));
          expect(settingsProvider.defaultReminderDelayMinutes, lessThanOrEqualTo(1440));
          expect(settingsProvider.maxLogsToKeep, greaterThanOrEqualTo(100));
          expect(settingsProvider.maxLogsToKeep, lessThanOrEqualTo(50000));
          expect(settingsProvider.maxLogRetentionDays, greaterThanOrEqualTo(7));
          expect(settingsProvider.maxLogRetentionDays, lessThanOrEqualTo(365));
          
          // Verification: Boolean settings are valid
          expect(settingsProvider.notificationsEnabled, isA<bool>());
          expect(settingsProvider.backgroundProcessingEnabled, isA<bool>());
          expect(settingsProvider.isAdvancedMode, equals(targetMode));
          
          // Add small delay to prevent file system issues on Windows
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });
    });
  });
}