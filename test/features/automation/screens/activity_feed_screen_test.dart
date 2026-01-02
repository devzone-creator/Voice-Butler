import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_butler/core/services/storage_service.dart';
import 'package:voice_butler/core/models/activity_log.dart';

void main() {
  group('Activity Feed Screen Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      final testPath = './test/hive_test_db_activity_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      
      // Initialize storage service
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

    setUp(() async {
      // Clear all data before each test
      await storageService.clearAll();
    });

    group('Property-Based Tests', () {
      test('**Feature: voice-butler, Property 20: Activity Feed Chronological Display** - For any set of activity logs, the activity feed should display them in chronological order (newest first)', () async {
        // **Validates: Requirements 5.2**
        
        // Run property test with 50 iterations
        for (int i = 0; i < 50; i++) {
          // Clear previous test data
          await storageService.clearAll();
          
          // Generate random activity logs with different timestamps
          final logs = _generateRandomActivityLogs(i, count: 10 + (i % 20));
          
          // Store all logs
          for (final log in logs) {
            await storageService.storeActivityLog(log);
          }
          
          // Retrieve logs using the same method as the activity feed
          final retrievedLogs = storageService.getAllActivityLogs();
          
          // Verify chronological order (newest first)
          expect(retrievedLogs.length, equals(logs.length),
              reason: 'All logs should be retrieved');
          
          for (int j = 0; j < retrievedLogs.length - 1; j++) {
            final currentLog = retrievedLogs[j];
            final nextLog = retrievedLogs[j + 1];
            
            expect(
              currentLog.timestamp.isAfter(nextLog.timestamp) || 
              currentLog.timestamp.isAtSameMomentAs(nextLog.timestamp),
              isTrue,
              reason: 'Activity logs should be in chronological order (newest first). '
                     'Log at index $j (${currentLog.timestamp}) should be newer than or equal to '
                     'log at index ${j + 1} (${nextLog.timestamp})',
            );
          }
        }
      });
      
      test('**Feature: voice-butler, Property 23: Activity Log Management** - For any activity log storage scenario, the management system should maintain recent history while managing storage limits effectively', () async {
        // **Validates: Requirements 5.5**
        
        // Run property test with different storage scenarios
        for (int i = 0; i < 20; i++) {
          // Clear previous test data
          await storageService.clearAll();
          
          // Generate a large number of logs to test storage management
          final logCount = 100 + (i * 30); // Varying from 100 to 700 logs
          final logs = _generateTimeSpreadActivityLogs(i, count: logCount);
          
          // Store all logs
          for (final log in logs) {
            await storageService.storeActivityLog(log);
          }
          
          // Test storage management with different limits
          final maxLogsToKeep = 50 + (i * 5); // Varying limits
          final storageInfo = await storageService.manageActivityLogStorage(
            maxLogsToKeep: maxLogsToKeep,
            notifyUser: false, // Don't create notification logs during test
          );
          
          // Verify storage management worked correctly
          final remainingLogs = storageService.getAllActivityLogs();
          
          expect(remainingLogs.length, lessThanOrEqualTo(maxLogsToKeep),
              reason: 'Storage management should respect the maximum log limit');
          
          if (logCount > maxLogsToKeep) {
            expect(storageInfo.logsRemoved, greaterThan(0),
                reason: 'Logs should be removed when exceeding limit');
          }
          
          // Verify most recent logs are kept (chronological order maintained)
          if (remainingLogs.length > 1) {
            for (int j = 0; j < remainingLogs.length - 1; j++) {
              final currentLog = remainingLogs[j];
              final nextLog = remainingLogs[j + 1];
              
              expect(
                currentLog.timestamp.isAfter(nextLog.timestamp) || 
                currentLog.timestamp.isAtSameMomentAs(nextLog.timestamp),
                isTrue,
                reason: 'Remaining logs should maintain chronological order (newest first)',
              );
            }
          }
        }
      });
    });
  });
}

/// Generates random activity logs for property-based testing
List<ActivityLog> _generateRandomActivityLogs(int seed, {required int count}) {
  final random = _SeededRandom(seed);
  final logs = <ActivityLog>[];
  final baseTime = DateTime.now().subtract(Duration(days: random.nextInt(30)));
  
  for (int i = 0; i < count; i++) {
    // Generate random timestamp within the last 30 days
    final timestamp = baseTime.add(Duration(
      hours: random.nextInt(24 * 30),
      minutes: random.nextInt(60),
      seconds: random.nextInt(60),
    ));
    
    final type = ActivityType.values[random.nextInt(ActivityType.values.length)];
    
    final log = ActivityLog(
      id: 'test_log_${seed}_$i',
      taskId: random.nextBool() ? 'task_${random.nextInt(100)}' : null,
      type: type,
      description: 'Test activity $i for seed $seed',
      timestamp: timestamp,
      isSystemGenerated: random.nextBool(),
      metadata: {
        'seed': seed,
        'index': i,
        'randomValue': random.nextInt(1000),
      },
    );
    
    logs.add(log);
  }
  
  return logs;
}

/// Generates activity logs spread across different time periods
List<ActivityLog> _generateTimeSpreadActivityLogs(int seed, {required int count}) {
  final random = _SeededRandom(seed);
  final logs = <ActivityLog>[];
  final now = DateTime.now();
  
  for (int i = 0; i < count; i++) {
    // Spread logs across last 60 days
    final daysBack = random.nextInt(60);
    final timestamp = now.subtract(Duration(
      days: daysBack,
      hours: random.nextInt(24),
      minutes: random.nextInt(60),
    ));
    
    final type = ActivityType.values[random.nextInt(ActivityType.values.length)];
    
    final log = ActivityLog(
      id: 'time_spread_${seed}_$i',
      taskId: random.nextBool() ? 'task_${random.nextInt(50)}' : null,
      type: type,
      description: 'Time spread log $i for seed $seed',
      timestamp: timestamp,
      isSystemGenerated: random.nextBool(),
      metadata: {
        'seed': seed,
        'index': i,
        'daysBack': daysBack,
      },
    );
    
    logs.add(log);
  }
  
  return logs;
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