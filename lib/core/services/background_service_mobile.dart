import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import 'storage_service.dart';

/// Mobile implementation for background service
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  static BackgroundService get instance => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;
  Timer? _cleanupTimer;
  Timer? _reminderTimer;

  bool get isInitialized => _isInitialized;

  /// Initialize background service for mobile
  Future<bool> initialize() async {
    try {
      // In a full implementation, this would use workmanager package
      _isInitialized = true;
      await _startPeriodicTasks();
      await _logActivity('Background service initialized (mobile)');
      return true;
    } catch (e) {
      await _logError('Failed to initialize mobile background service: $e');
      return false;
    }
  }

  /// Start periodic background tasks
  Future<void> _startPeriodicTasks() async {
    // Start cleanup timer (runs every hour)
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _performCleanup();
    });

    // Start reminder timer (runs every 15 minutes)
    _reminderTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _checkReminders();
    });
  }

  /// Perform cleanup tasks
  Future<void> _performCleanup() async {
    try {
      final storageService = StorageService.instance;
      
      // Clean up old soft-deleted tasks
      final tasks = storageService.getAllTasks();
      int cleanedCount = 0;
      
      for (final task in tasks) {
        if (task.shouldAutoCleanup()) {
          await storageService.deleteTask(task.id, permanent: true);
          cleanedCount++;
        }
      }
      
      if (cleanedCount > 0) {
        await _logActivity('Cleaned up $cleanedCount old tasks');
      }
      
      // Clean up old activity logs
      await storageService.manageActivityLogStorage();
      
    } catch (e) {
      await _logError('Cleanup task failed: $e');
    }
  }

  /// Check for task reminders
  Future<void> _checkReminders() async {
    try {
      final storageService = StorageService.instance;
      final tasks = storageService.getAllTasks();
      
      for (final task in tasks) {
        if (task.hasDeadlineApproaching()) {
          await _logActivity('Reminder: Task "${task.title}" deadline approaching');
        }
      }
    } catch (e) {
      await _logError('Reminder check failed: $e');
    }
  }

  /// Schedule a background job (mobile-specific)
  Future<void> scheduleJob({
    required String jobName,
    required Duration delay,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // In a full implementation, this would use workmanager
    Timer(delay, () async {
      await _executeJob(jobName, data);
    });

    await _logActivity('Mobile job scheduled: $jobName');
  }

  /// Execute a background job
  Future<void> _executeJob(String jobName, Map<String, dynamic> data) async {
    try {
      switch (jobName) {
        case 'cleanup_old_tasks':
          await _performCleanup();
          break;
        case 'task_reminder':
          await _checkReminders();
          break;
        default:
          await _logActivity('Unknown mobile job executed: $jobName');
      }
    } catch (e) {
      await _logError('Mobile job execution failed: $jobName - $e');
    }
  }

  /// Stop background service
  Future<void> stop() async {
    _cleanupTimer?.cancel();
    _reminderTimer?.cancel();
    _isInitialized = false;
    await _logActivity('Mobile background service stopped');
  }

  /// Log activity
  Future<void> _logActivity(String message) async {
    try {
      final log = ActivityLog.create(
        type: ActivityType.automationApplied,
        description: message,
        metadata: const {'service': 'background_mobile'},
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log mobile background activity: $e');
      }
    }
  }

  /// Log error
  Future<void> _logError(String errorMessage) async {
    try {
      final log = ActivityLog.errorOccurred(
        errorMessage: errorMessage,
        additionalMetadata: const {'service': 'background_mobile'},
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log mobile background error: $e');
      }
    }
  }
}