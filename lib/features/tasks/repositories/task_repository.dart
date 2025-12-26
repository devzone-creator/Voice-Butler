import 'package:hive/hive.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';

/// Repository for managing task data persistence and retrieval
class TaskRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  static TaskRepository get instance => _instance;
  TaskRepository._internal();

  Box get _tasksBox => StorageService.instance.tasksBox;

  /// Creates a new task and stores it
  Future<Task> createTask(Task task) async {
    try {
      await _tasksBox.put(task.id, task);
      return task;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Updates an existing task
  Future<Task> updateTask(Task task) async {
    try {
      await _tasksBox.put(task.id, task);
      return task;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Retrieves a task by ID
  Task? getTaskById(String id) {
    try {
      return _tasksBox.get(id) as Task?;
    } catch (e) {
      return null;
    }
  }

  /// Retrieves all tasks
  List<Task> getAllTasks() {
    try {
      return _tasksBox.values.cast<Task>().toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves all pending tasks (not deleted or completed)
  List<Task> getPendingTasks() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.status == TaskStatus.pending && !task.isDeleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves all completed tasks
  List<Task> getCompletedTasks() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.status == TaskStatus.completed && !task.isDeleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves all soft-deleted tasks
  List<Task> getSoftDeletedTasks() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.isDeleted && task.recentDeleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves tasks with approaching deadlines (within 24 hours)
  List<Task> getTasksWithApproachingDeadlines() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.hasDeadlineApproaching())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves high priority tasks
  List<Task> getHighPriorityTasks() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => 
              task.priority == TaskPriority.high && 
              task.status == TaskStatus.pending && 
              !task.isDeleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Retrieves overdue tasks
  List<Task> getOverdueTasks() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.isOverdue)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Marks a task as completed
  Future<Task> completeTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    final completedTask = task.markCompleted();
    return await updateTask(completedTask);
  }

  /// Soft deletes a task
  Future<Task> softDeleteTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    final deletedTask = task.markSoftDeleted();
    return await updateTask(deletedTask);
  }

  /// Restores a soft-deleted task
  Future<Task> restoreTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw Exception('Task not found');
    }

    final restoredTask = task.restore();
    return await updateTask(restoredTask);
  }

  /// Permanently deletes a task
  Future<void> permanentlyDeleteTask(String taskId) async {
    try {
      await _tasksBox.delete(taskId);
    } catch (e) {
      throw Exception('Failed to permanently delete task: $e');
    }
  }

  /// Gets tasks that should be automatically cleaned up (older than 7 days)
  List<Task> getTasksForAutoCleanup() {
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) => task.shouldAutoCleanup())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Performs automatic cleanup of old soft-deleted tasks
  Future<int> performAutoCleanup() async {
    final tasksToCleanup = getTasksForAutoCleanup();
    int cleanedCount = 0;

    for (final task in tasksToCleanup) {
      try {
        await permanentlyDeleteTask(task.id);
        cleanedCount++;
      } catch (e) {
        // Log error but continue with other tasks
        print('Failed to cleanup task ${task.id}: $e');
      }
    }

    return cleanedCount;
  }

  /// Searches tasks by title or reason
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return getAllTasks();

    final lowercaseQuery = query.toLowerCase();
    try {
      return _tasksBox.values
          .cast<Task>()
          .where((task) =>
              !task.isDeleted &&
              (task.title.toLowerCase().contains(lowercaseQuery) ||
               (task.reason?.toLowerCase().contains(lowercaseQuery) ?? false)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets task statistics
  Map<String, int> getTaskStatistics() {
    try {
      final allTasks = getAllTasks();
      final activeTasks = allTasks.where((task) => !task.isDeleted).toList();
      
      return {
        'total': allTasks.length,
        'pending': activeTasks.where((task) => task.status == TaskStatus.pending).length,
        'completed': activeTasks.where((task) => task.status == TaskStatus.completed).length,
        'softDeleted': allTasks.where((task) => task.isDeleted).length,
        'highPriority': activeTasks.where((task) => task.priority == TaskPriority.high).length,
        'overdue': activeTasks.where((task) => task.isOverdue).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'completed': 0,
        'softDeleted': 0,
        'highPriority': 0,
        'overdue': 0,
      };
    }
  }

  /// Clears all tasks (for testing purposes)
  Future<void> clearAllTasks() async {
    try {
      await _tasksBox.clear();
    } catch (e) {
      throw Exception('Failed to clear all tasks: $e');
    }
  }
}