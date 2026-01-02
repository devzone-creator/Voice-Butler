import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// Web-compatible background service using timers and periodic checks
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static BackgroundService get instance => _instance;
  BackgroundService._internal();

  Timer? _cleanupTimer;
  Timer? _reminderCheckTimer;

  Future<void> initialize() async {
    if (kDebugMode) {
      print('Initializing web background service');
    }

    // Schedule periodic cleanup task (runs every 24 hours)
    _schedulePeriodicCleanup();

    // Schedule reminder checker (runs every minute)
    _scheduleReminderChecker();
  }

  /// Schedules periodic cleanup task
  void _schedulePeriodicCleanup() {
    _cleanupTimer?.cancel();
    
    // Run cleanup immediately, then every 24 hours
    _performCleanupTask();
    
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _performCleanupTask();
    });
  }

  /// Schedules reminder checker that runs every minute
  void _scheduleReminderChecker() {
    _reminderCheckTimer?.cancel();
    
    // Check for due reminders every minute
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkScheduledReminders();
    });
  }

  /// Performs cleanup task
  Future<void> _performCleanupTask() async {
    try {
      if (kDebugMode) {
        print('Running cleanup task');
      }

      final deletedCount = await StorageService.instance.performTaskAutoCleanup();
      
      if (kDebugMode) {
        print('Cleanup completed: $deletedCount tasks removed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in cleanup task: $e');
      }
    }
  }
  /// Checks for scheduled reminders that are due
  Future<void> _checkScheduledReminders() async {
    try {
      final tasks = StorageService.instance.getAllTasks();
      final now = DateTime.now();

      for (final task in tasks) {
        if (task.deadline != null && 
            task.status == TaskStatus.pending && 
            !task.isDeleted) {
          
          final hoursUntilDeadline = task.deadline!.difference(now).inHours;
          
          // Send reminder within 24 hours
          if (hoursUntilDeadline <= 24 && hoursUntilDeadline > 0) {
            await _sendTaskReminder(task);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking scheduled reminders: $e');
      }
    }
  }
  /// Sends a task reminder notification
  Future<void> _sendTaskReminder(Task task) async {
    try {
      await NotificationService.instance.showNotification(
        title: 'Task Reminder',
        message: 'Task "${task.title}" deadline is approaching',
        taskId: task.id,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send task reminder: $e');
      }
    }
  }
  /// Schedule a background job
  Future<void> scheduleJob({
    required String jobName,
    required Duration delay,
    required Map<String, dynamic> data,
  }) async {
    if (kDebugMode) {
      print('Scheduling job: $jobName with delay: $delay');
    }

    // Simple timer-based scheduling for web
    Timer(delay, () async {
      await _executeJob(jobName, data);
    });
  }
  /// Execute a background job
  Future<void> _executeJob(String jobName, Map<String, dynamic> data) async {
    try {
      switch (jobName) {
        case 'task_reminder':
          await _handleTaskReminder(data);
          break;
        case 'cleanup_old_tasks':
          await _performCleanupTask();
          break;
        default:
          if (kDebugMode) {
            print('Unknown job executed: $jobName');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Job execution failed: $jobName - $e');
      }
    }
  }
  /// Handle task reminder job
  Future<void> _handleTaskReminder(Map<String, dynamic> data) async {
    try {
      final taskId = data['taskId'] as String?;
      final message = data['message'] as String?;
      
      if (taskId != null && message != null) {
        await NotificationService.instance.showNotification(
          title: 'Task Reminder',
          message: message,
          taskId: taskId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to handle task reminder: $e');
      }
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _reminderCheckTimer?.cancel();
  }
}