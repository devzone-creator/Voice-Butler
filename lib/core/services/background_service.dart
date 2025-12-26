import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case AppConfig.cleanupJobName:
          await _performCleanupTask();
          break;
        case AppConfig.reminderJobName:
          await _performReminderTask(inputData);
          break;
        default:
          if (kDebugMode) {
            print('Unknown background task: $task');
          }
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Background task failed: $e');
      }
      return Future.value(false);
    }
  });
}

Future<void> _performCleanupTask() async {
  // Initialize storage for background task
  await StorageService.instance.initialize();
  
  final tasksBox = StorageService.instance.tasksBox;
  final now = DateTime.now();
  final cutoffDate = now.subtract(const Duration(days: AppConfig.softDeleteRetentionDays));
  
  // Find and remove old soft-deleted tasks
  final keysToDelete = <dynamic>[];
  
  for (final key in tasksBox.keys) {
    final taskData = tasksBox.get(key) as Map<dynamic, dynamic>?;
    if (taskData != null) {
      final isDeleted = taskData['isDeleted'] as bool? ?? false;
      final deletedAtStr = taskData['deletedAt'] as String?;
      
      if (isDeleted && deletedAtStr != null) {
        final deletedAt = DateTime.parse(deletedAtStr);
        if (deletedAt.isBefore(cutoffDate)) {
          keysToDelete.add(key);
        }
      }
    }
  }
  
  // Remove old tasks
  for (final key in keysToDelete) {
    await tasksBox.delete(key);
  }
  
  if (kDebugMode) {
    print('Cleanup completed: removed ${keysToDelete.length} old tasks');
  }
}

Future<void> _performReminderTask(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;
  
  // Handle task reminder logic
  final taskId = inputData['taskId'] as String?;
  final reminderType = inputData['reminderType'] as String?;
  
  if (taskId != null && reminderType != null) {
    // Send notification for task reminder
    if (kDebugMode) {
      print('Sending reminder for task: $taskId, type: $reminderType');
    }
  }
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static BackgroundService get instance => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Schedule daily cleanup task
    await scheduleCleanupTask();
  }

  Future<void> scheduleCleanupTask() async {
    await Workmanager().registerPeriodicTask(
      AppConfig.cleanupJobName,
      AppConfig.cleanupJobName,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required DateTime reminderTime,
    required String reminderType,
  }) async {
    final uniqueId = '${AppConfig.reminderJobName}_${taskId}_$reminderType';
    
    await Workmanager().registerOneOffTask(
      uniqueId,
      AppConfig.reminderJobName,
      initialDelay: reminderTime.difference(DateTime.now()),
      inputData: {
        'taskId': taskId,
        'reminderType': reminderType,
      },
    );
  }

  Future<void> cancelTaskReminder(String taskId, String reminderType) async {
    final uniqueId = '${AppConfig.reminderJobName}_${taskId}_$reminderType';
    await Workmanager().cancelByUniqueName(uniqueId);
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}