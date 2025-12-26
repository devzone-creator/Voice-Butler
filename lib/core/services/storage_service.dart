import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../app_config.dart';
import '../models/task.dart';
import '../models/automation_rule.dart';
import '../models/activity_log.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  late Box _tasksBox;
  late Box _automationRulesBox;
  late Box _activityLogsBox;
  late Box _settingsBox;

  // In-memory caches for performance
  final Map<String, Task> _taskCache = {};
  final Map<String, AutomationRule> _ruleCache = {};
  final Map<String, ActivityLog> _logCache = {};
  
  // Cache invalidation flags
  bool _taskCacheValid = false;
  bool _ruleCacheValid = false;
  bool _logCacheValid = false;
  
  // Cleanup timer
  Timer? _cleanupTimer;

  Box get tasksBox => _tasksBox;
  Box get automationRulesBox => _automationRulesBox;
  Box get activityLogsBox => _activityLogsBox;
  Box get settingsBox => _settingsBox;

  Future<void> initialize() async {
    try {
      // Register Hive adapters for Task model
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TaskPriorityAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TaskStatusAdapter());
      }

      // Register Hive adapters for AutomationRule model
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(RuleTriggerAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(RuleConditionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(RuleActionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(RuleConditionAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(RuleActionAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(AutomationRuleAdapter());
      }

      // Register Hive adapters for ActivityLog model
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }

      _tasksBox = await Hive.openBox(AppConfig.tasksBoxKey);
      _automationRulesBox = await Hive.openBox(AppConfig.automationRulesBoxKey);
      _activityLogsBox = await Hive.openBox(AppConfig.activityLogsBoxKey);
      _settingsBox = await Hive.openBox(AppConfig.settingsBoxKey);
      
      // Initialize caches
      await _initializeCaches();
      
      // Start automatic cleanup timer
      _startCleanupTimer();
      
    } catch (e) {
      throw Exception('Failed to initialize storage: $e');
    }
  }

  /// Initializes in-memory caches from storage
  Future<void> _initializeCaches() async {
    try {
      // Load tasks into cache
      _taskCache.clear();
      for (final key in _tasksBox.keys) {
        final task = _tasksBox.get(key) as Task?;
        if (task != null) {
          _taskCache[task.id] = task;
        }
      }
      _taskCacheValid = true;

      // Load automation rules into cache
      _ruleCache.clear();
      for (final key in _automationRulesBox.keys) {
        final rule = _automationRulesBox.get(key) as AutomationRule?;
        if (rule != null) {
          _ruleCache[rule.id] = rule;
        }
      }
      _ruleCacheValid = true;

      // Load activity logs into cache (limit to recent entries)
      _logCache.clear();
      final logs = _activityLogsBox.values.cast<ActivityLog>().toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Keep only the most recent 1000 logs in cache
      final recentLogs = logs.take(1000);
      for (final log in recentLogs) {
        _logCache[log.id] = log;
      }
      _logCacheValid = true;
      
    } catch (e) {
      print('Warning: Failed to initialize caches: $e');
      // Continue without caches if initialization fails
      _taskCacheValid = false;
      _ruleCacheValid = false;
      _logCacheValid = false;
    }
  }

  /// Starts the automatic cleanup timer
  void _startCleanupTimer() {
    // Run cleanup every 24 hours
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _performAutomaticCleanup();
    });
    
    // Also run cleanup on startup
    _performAutomaticCleanup();
  }

  /// Performs automatic cleanup of old soft-deleted tasks
  Future<void> _performAutomaticCleanup() async {
    try {
      final tasksToDelete = <String>[];
      
      // Find tasks that should be cleaned up
      for (final task in getAllTasks()) {
        if (task.shouldAutoCleanup()) {
          tasksToDelete.add(task.id);
        }
      }
      
      // Permanently delete old tasks
      for (final taskId in tasksToDelete) {
        await permanentlyDeleteTask(taskId);
      }
      
      // Log cleanup activity if any tasks were deleted
      if (tasksToDelete.isNotEmpty) {
        final cleanupLog = ActivityLog.cleanupPerformed(
          tasksCleanedCount: tasksToDelete.length,
        );
        await storeActivityLog(cleanupLog);
      }
      
      // Also cleanup old activity logs (keep only last 30 days)
      await _cleanupOldActivityLogs();
      
    } catch (e) {
      print('Error during automatic cleanup: $e');
      // Log the error
      final errorLog = ActivityLog.errorOccurred(
        errorMessage: 'Automatic cleanup failed: $e',
      );
      await storeActivityLog(errorLog);
    }
  }

  /// Cleans up old activity logs
  Future<void> _cleanupOldActivityLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final logsToDelete = <String>[];
      
      for (final log in getAllActivityLogs()) {
        if (log.timestamp.isBefore(cutoffDate)) {
          logsToDelete.add(log.id);
        }
      }
      
      // Delete old logs
      for (final logId in logsToDelete) {
        await _activityLogsBox.delete(logId);
        _logCache.remove(logId);
      }
      
    } catch (e) {
      print('Error cleaning up old activity logs: $e');
    }
  }

  Future<void> clearAll() async {
    await _tasksBox.clear();
    await _automationRulesBox.clear();
    await _activityLogsBox.clear();
    await _settingsBox.clear();
    
    // Clear caches
    _taskCache.clear();
    _ruleCache.clear();
    _logCache.clear();
    _taskCacheValid = false;
    _ruleCacheValid = false;
    _logCacheValid = false;
  }

  Future<void> close() async {
    // Cancel cleanup timer
    _cleanupTimer?.cancel();
    
    await _tasksBox.close();
    await _automationRulesBox.close();
    await _activityLogsBox.close();
    await _settingsBox.close();
    
    // Clear caches
    _taskCache.clear();
    _ruleCache.clear();
    _logCache.clear();
  }

  // ==================== TASK MANAGEMENT ====================

  /// Stores a task with caching
  Future<void> storeTask(Task task) async {
    try {
      await _tasksBox.put(task.id, task);
      _taskCache[task.id] = task;
    } catch (e) {
      throw Exception('Failed to store task: $e');
    }
  }

  /// Gets a task by ID with caching
  Task? getTask(String id) {
    try {
      if (_taskCacheValid && _taskCache.containsKey(id)) {
        return _taskCache[id];
      }
      
      final task = _tasksBox.get(id) as Task?;
      if (task != null && _taskCacheValid) {
        _taskCache[id] = task;
      }
      return task;
    } catch (e) {
      return null;
    }
  }

  /// Gets all tasks with caching
  List<Task> getAllTasks() {
    try {
      if (_taskCacheValid) {
        return _taskCache.values.toList();
      }
      
      final tasks = _tasksBox.values.cast<Task>().toList();
      
      // Update cache if valid
      if (_taskCacheValid) {
        _taskCache.clear();
        for (final task in tasks) {
          _taskCache[task.id] = task;
        }
      }
      
      return tasks;
    } catch (e) {
      return [];
    }
  }

  /// Gets pending tasks (not deleted or completed)
  List<Task> getPendingTasks() {
    return getAllTasks()
        .where((task) => task.status == TaskStatus.pending && !task.isDeleted)
        .toList();
  }

  /// Gets completed tasks
  List<Task> getCompletedTasks() {
    return getAllTasks()
        .where((task) => task.status == TaskStatus.completed && !task.isDeleted)
        .toList();
  }

  /// Gets soft-deleted tasks
  List<Task> getSoftDeletedTasks() {
    return getAllTasks()
        .where((task) => task.isDeleted && task.recentDeleted)
        .toList();
  }

  /// Gets tasks with approaching deadlines
  List<Task> getTasksWithApproachingDeadlines() {
    return getAllTasks()
        .where((task) => task.hasDeadlineApproaching())
        .toList();
  }

  /// Gets high priority tasks
  List<Task> getHighPriorityTasks() {
    return getAllTasks()
        .where((task) => 
            task.priority == TaskPriority.high && 
            task.status == TaskStatus.pending && 
            !task.isDeleted)
        .toList();
  }

  /// Gets overdue tasks
  List<Task> getOverdueTasks() {
    return getAllTasks()
        .where((task) => task.isOverdue)
        .toList();
  }

  /// Permanently deletes a task
  Future<void> permanentlyDeleteTask(String taskId) async {
    try {
      await _tasksBox.delete(taskId);
      _taskCache.remove(taskId);
    } catch (e) {
      throw Exception('Failed to permanently delete task: $e');
    }
  }

  /// Updates a task with caching
  Future<void> updateTask(Task task) async {
    await storeTask(task); // storeTask handles both create and update
  }

  /// Searches tasks by query
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return getAllTasks();

    final lowercaseQuery = query.toLowerCase();
    return getAllTasks()
        .where((task) =>
            !task.isDeleted &&
            (task.title.toLowerCase().contains(lowercaseQuery) ||
             (task.reason?.toLowerCase().contains(lowercaseQuery) ?? false)))
        .toList();
  }

  // ==================== AUTOMATION RULE MANAGEMENT ====================

  /// Stores an automation rule with caching
  Future<void> storeAutomationRule(AutomationRule rule) async {
    try {
      await _automationRulesBox.put(rule.id, rule);
      _ruleCache[rule.id] = rule;
    } catch (e) {
      throw Exception('Failed to store automation rule: $e');
    }
  }

  /// Gets an automation rule by ID with caching
  AutomationRule? getAutomationRule(String id) {
    try {
      if (_ruleCacheValid && _ruleCache.containsKey(id)) {
        return _ruleCache[id];
      }
      
      final rule = _automationRulesBox.get(id) as AutomationRule?;
      if (rule != null && _ruleCacheValid) {
        _ruleCache[id] = rule;
      }
      return rule;
    } catch (e) {
      return null;
    }
  }

  /// Gets all automation rules with caching
  List<AutomationRule> getAllAutomationRules() {
    try {
      if (_ruleCacheValid) {
        return _ruleCache.values.toList();
      }
      
      final rules = _automationRulesBox.values.cast<AutomationRule>().toList();
      
      // Update cache if valid
      if (_ruleCacheValid) {
        _ruleCache.clear();
        for (final rule in rules) {
          _ruleCache[rule.id] = rule;
        }
      }
      
      return rules;
    } catch (e) {
      return [];
    }
  }

  /// Gets active automation rules
  List<AutomationRule> getActiveAutomationRules() {
    return getAllAutomationRules()
        .where((rule) => rule.isActive)
        .toList();
  }

  /// Gets preset automation rules
  List<AutomationRule> getPresetAutomationRules() {
    return getAllAutomationRules()
        .where((rule) => rule.isPreset)
        .toList();
  }

  /// Deletes an automation rule
  Future<void> deleteAutomationRule(String ruleId) async {
    try {
      await _automationRulesBox.delete(ruleId);
      _ruleCache.remove(ruleId);
    } catch (e) {
      throw Exception('Failed to delete automation rule: $e');
    }
  }

  // ==================== ACTIVITY LOG MANAGEMENT ====================

  /// Stores an activity log with caching
  Future<void> storeActivityLog(ActivityLog log) async {
    try {
      await _activityLogsBox.put(log.id, log);
      _logCache[log.id] = log;
      
      // Limit cache size to prevent memory issues
      if (_logCache.length > 1000) {
        final sortedLogs = _logCache.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Keep only the most recent 800 logs in cache
        _logCache.clear();
        for (final recentLog in sortedLogs.take(800)) {
          _logCache[recentLog.id] = recentLog;
        }
      }
    } catch (e) {
      throw Exception('Failed to store activity log: $e');
    }
  }

  /// Gets an activity log by ID with caching
  ActivityLog? getActivityLog(String id) {
    try {
      if (_logCacheValid && _logCache.containsKey(id)) {
        return _logCache[id];
      }
      
      final log = _activityLogsBox.get(id) as ActivityLog?;
      if (log != null && _logCacheValid) {
        _logCache[id] = log;
      }
      return log;
    } catch (e) {
      return null;
    }
  }

  /// Gets all activity logs with caching (sorted by timestamp, newest first)
  List<ActivityLog> getAllActivityLogs() {
    try {
      List<ActivityLog> logs;
      
      if (_logCacheValid) {
        logs = _logCache.values.toList();
      } else {
        logs = _activityLogsBox.values.cast<ActivityLog>().toList();
      }
      
      // Sort by timestamp (newest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (e) {
      return [];
    }
  }

  /// Gets recent activity logs (last 100)
  List<ActivityLog> getRecentActivityLogs({int limit = 100}) {
    final allLogs = getAllActivityLogs();
    return allLogs.take(limit).toList();
  }

  /// Gets activity logs for a specific task
  List<ActivityLog> getActivityLogsForTask(String taskId) {
    return getAllActivityLogs()
        .where((log) => log.taskId == taskId)
        .toList();
  }

  /// Gets activity logs by type
  List<ActivityLog> getActivityLogsByType(ActivityType type) {
    return getAllActivityLogs()
        .where((log) => log.type == type)
        .toList();
  }

  /// Deletes an activity log
  Future<void> deleteActivityLog(String logId) async {
    try {
      await _activityLogsBox.delete(logId);
      _logCache.remove(logId);
    } catch (e) {
      throw Exception('Failed to delete activity log: $e');
    }
  }

  // ==================== SETTINGS MANAGEMENT ====================

  /// Gets a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Sets a setting value
  Future<void> setSetting<T>(String key, T value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      throw Exception('Failed to set setting: $e');
    }
  }

  /// Deletes a setting
  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      throw Exception('Failed to delete setting: $e');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Invalidates all caches
  void invalidateCaches() {
    _taskCacheValid = false;
    _ruleCacheValid = false;
    _logCacheValid = false;
    _taskCache.clear();
    _ruleCache.clear();
    _logCache.clear();
  }

  /// Refreshes all caches
  Future<void> refreshCaches() async {
    await _initializeCaches();
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'taskCacheSize': _taskCache.length,
      'ruleCacheSize': _ruleCache.length,
      'logCacheSize': _logCache.length,
      'taskCacheValid': _taskCacheValid,
      'ruleCacheValid': _ruleCacheValid,
      'logCacheValid': _logCacheValid,
    };
  }

  // ==================== STATISTICS ====================

  /// Gets storage statistics
  Map<String, dynamic> getStorageStatistics() {
    return {
      'totalTasks': _tasksBox.length,
      'totalRules': _automationRulesBox.length,
      'totalLogs': _activityLogsBox.length,
      'totalSettings': _settingsBox.length,
      'pendingTasks': getPendingTasks().length,
      'completedTasks': getCompletedTasks().length,
      'softDeletedTasks': getSoftDeletedTasks().length,
      'activeRules': getActiveAutomationRules().length,
      'presetRules': getPresetAutomationRules().length,
      ...getCacheStatistics(),
    };
  }
}