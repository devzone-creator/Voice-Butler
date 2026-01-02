import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../../../core/models/task.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recently-deleted',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Recently Deleted'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'recently-deleted') {
                context.push('/recently-deleted');
              }
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final pendingTasks = taskProvider.pendingTasks;
          final completedTasks = taskProvider.completedTasks;

          if (pendingTasks.isEmpty && completedTasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Use voice input to create your first task!'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingTasks.isNotEmpty) ...[
                Text('Pending Tasks', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...pendingTasks.map((task) => TaskCard(
                  task: task,
                  onComplete: () => _completeTaskWithFeedback(context, taskProvider, task),
                  onDelete: () => _deleteTaskWithFeedback(context, taskProvider, task),
                )),
                const SizedBox(height: 24),
              ],
              if (completedTasks.isNotEmpty) ...[
                Text('Completed Tasks', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...completedTasks.map((task) => TaskCard(
                  task: task,
                  onDelete: () => _deleteTaskWithFeedback(context, taskProvider, task),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _completeTaskWithFeedback(BuildContext context, TaskProvider taskProvider, Task task) async {
    final success = await taskProvider.completeTask(task.id);
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" completed! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task: ${taskProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTaskWithFeedback(BuildContext context, TaskProvider taskProvider, Task task) async {
    final success = await taskProvider.deleteTask(task.id);
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" moved to Recently Deleted'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => taskProvider.restoreTask(task.id),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: ${taskProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Tooltip(
          message: task.status == TaskStatus.pending ? 'Tap to complete' : 'Completed',
          child: GestureDetector(
            onTap: task.status == TaskStatus.pending ? onComplete : null,
            child: CircleAvatar(
              backgroundColor: _getPriorityColor(theme.colorScheme),
              child: Icon(
                task.status == TaskStatus.completed ? Icons.check : Icons.task,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Priority: ${task.priority.name.toUpperCase()}'),
            if (task.reason != null) Text('Reason: ${task.reason}'),
            if (task.deadline != null) 
              Text('Deadline: ${task.deadline!.toLocal().toString().split('.')[0]}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (onComplete != null)
              const PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Complete'),
                ),
              ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'complete':
                onComplete?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(ColorScheme colorScheme) {
    switch (task.priority) {
      case TaskPriority.high:
        return colorScheme.error;
      case TaskPriority.medium:
        return colorScheme.primary;
      case TaskPriority.low:
        return colorScheme.secondary;
    }
  }
}