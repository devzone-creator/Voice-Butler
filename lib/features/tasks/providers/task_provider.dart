import 'package:flutter/foundation.dart';
import '../../../core/models/task.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/services/storage_service.dart';
import '../repositories/task_repository.dart';

/// Provider for managing task state and operations
class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository.instance;

  List<Task> _tasks = [];
  List<Task> _pendingTasks = [];
  List<Task> _completedTasks = [];
  List<Task> _softDeletedTasks = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider() {
    // Load tasks when provider is created
    initialize();
  }

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks => _pendingTasks;
  List<Task> get completedTasks => _completedTasks;
  List<Task> get softDeletedTasks => _softDeletedTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initializes the provider by loading tasks from storage
  Future<void> initialize() async {
    await loadTasks();
  }

  /// Loads all tasks from the repository
  Future<void> loadTasks() async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = _repository.getAllTasks();
      _pendingTasks = _repository.getPendingTasks();
      _completedTasks = _repository.getCompletedTasks();
      _softDeletedTasks = _repository.getSoftDeletedTasks();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new task
  Future<Task?> createTask({
    required String title,
    required TaskPriority priority,
    String? reason,
    DateTime? deadline,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final task = Task.create(
        title: title,
        priority: priority,
        reason: reason,
        deadline: deadline,
      );

      final createdTask = await _repository.createTask(task);
      await loadTasks(); // Refresh the lists
      
      // Trigger automation rules for task creation
      // Temporarily disabled for demo
      // if (_automationProvider != null) {
      //   await _automationProvider!.onTaskCreated(createdTask);
      // }
      
      return createdTask;
    } catch (e) {
      _setError('Failed to create task: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing task
  Future<Task?> updateTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedTask = await _repository.updateTask(task);
      await loadTasks(); // Refresh the lists
      return updatedTask;
    } catch (e) {
      _setError('Failed to update task: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Marks a task as completed
  Future<bool> completeTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final task = _repository.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        return false;
      }

      await _repository.completeTask(taskId);
      await loadTasks(); // Refresh the lists
      
      // Log the completion activity
      await _logTaskCompletion('Task completed: "${task.title}"', task.id);
      
      // Trigger automation rules for task completion
      // Temporarily disabled for demo
      // if (_automationProvider != null) {
      //   final completedTask = task.markCompleted();
      //   await _automationProvider!.onTaskCompleted(completedTask);
      // }
      
      return true;
    } catch (e) {
      _setError('Failed to complete task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Soft deletes a task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final task = _repository.getTaskById(taskId);
      if (task == null) {
        _setError('Task not found');
        return false;
      }

      await _repository.softDeleteTask(taskId);
      await loadTasks(); // Refresh the lists
      
      // Log the deletion activity
      await _logTaskDeletion('Task moved to Recently Deleted: "${task.title}"', task.id);
      
      // Trigger automation rules for task deletion
      // Temporarily disabled for demo
      // if (_automationProvider != null) {
      //   final deletedTask = task.markSoftDeleted();
      //   await _automationProvider!.onTaskDeleted(deletedTask);
      // }
      
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restores a soft-deleted task
  Future<bool> restoreTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.restoreTask(taskId);
      await loadTasks(); // Refresh the lists
      return true;
    } catch (e) {
      _setError('Failed to restore task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Permanently deletes a task
  Future<bool> permanentlyDeleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.permanentlyDeleteTask(taskId);
      await loadTasks(); // Refresh the lists
      return true;
    } catch (e) {
      _setError('Failed to permanently delete task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Gets a task by ID
  Task? getTaskById(String id) {
    return _repository.getTaskById(id);
  }

  /// Gets tasks with approaching deadlines
  List<Task> getTasksWithApproachingDeadlines() {
    return _repository.getTasksWithApproachingDeadlines();
  }

  /// Gets high priority tasks
  List<Task> getHighPriorityTasks() {
    return _repository.getHighPriorityTasks();
  }

  /// Gets overdue tasks
  List<Task> getOverdueTasks() {
    return _repository.getOverdueTasks();
  }

  /// Searches tasks by query
  List<Task> searchTasks(String query) {
    return _repository.searchTasks(query);
  }

  /// Gets task statistics
  Map<String, int> getTaskStatistics() {
    return _repository.getTaskStatistics();
  }

  /// Performs automatic cleanup of old soft-deleted tasks
  Future<int> performAutoCleanup() async {
    _setLoading(true);
    _clearError();

    try {
      final cleanedCount = await _repository.performAutoCleanup();
      await loadTasks(); // Refresh the lists
      return cleanedCount;
    } catch (e) {
      _setError('Failed to perform auto cleanup: $e');
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  /// Clears all tasks (for testing)
  Future<void> clearAllTasks() async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.clearAllTasks();
      await loadTasks(); // Refresh the lists
    } catch (e) {
      _setError('Failed to clear all tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sets loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Logs task completion activity
  Future<void> _logTaskCompletion(String message, String taskId) async {
    try {
      final log = ActivityLog.create(
        taskId: taskId,
        type: ActivityType.taskCompleted,
        description: message,
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log task completion: $e');
      }
    }
  }

  /// Logs task deletion activity
  Future<void> _logTaskDeletion(String message, String taskId) async {
    try {
      final log = ActivityLog.create(
        taskId: taskId,
        type: ActivityType.taskDeleted,
        description: message,
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log task deletion: $e');
      }
    }
  }
}