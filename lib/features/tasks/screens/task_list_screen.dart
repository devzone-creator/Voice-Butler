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
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => context.push('/recently-deleted'),
            tooltip: 'Recently Deleted',
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final pendingTasks = taskProvider.pendingTasks;
          final completedTasks = taskProvider.completedTasks;

          if (pendingTasks.isEmpty && completedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt, 
                    size: 64, 
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use voice input to create your first task!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.mic),
                    label: const Text('Create Task'),
                  ),
                ],
              ),
            );
          }

          // Sort pending tasks by priority and deadline
          final sortedPendingTasks = List<Task>.from(pendingTasks)
            ..sort((a, b) {
              // First sort by overdue status
              if (a.isOverdue && !b.isOverdue) return -1;
              if (!a.isOverdue && b.isOverdue) return 1;
              
              // Then by approaching deadline
              if (a.hasDeadlineApproaching() && !b.hasDeadlineApproaching()) return -1;
              if (!a.hasDeadlineApproaching() && b.hasDeadlineApproaching()) return 1;
              
              // Then by priority
              final priorityComparison = b.priority.index.compareTo(a.priority.index);
              if (priorityComparison != 0) return priorityComparison;
              
              // Finally by creation date (newest first)
              return b.createdAt.compareTo(a.createdAt);
            });

          return RefreshIndicator(
            onRefresh: () async {
              await taskProvider.loadTasks();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (sortedPendingTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    context, 
                    'Pending Tasks', 
                    sortedPendingTasks.length,
                    Icons.pending_actions,
                  ),
                  const SizedBox(height: 12),
                  ...sortedPendingTasks.map((task) => TaskCard(
                    task: task,
                    onComplete: () => _completeTask(context, taskProvider, task),
                    onDelete: () => _deleteTask(context, taskProvider, task),
                  )),
                  const SizedBox(height: 24),
                ],
                if (completedTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    context, 
                    'Completed Tasks', 
                    completedTasks.length,
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 12),
                  ...completedTasks.take(5).map((task) => TaskCard(
                    task: task,
                    onDelete: () => _deleteTask(context, taskProvider, task),
                  )),
                  if (completedTasks.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Show all completed tasks
                        },
                        child: Text('Show ${completedTasks.length - 5} more completed tasks'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/'),
        tooltip: 'Create Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _completeTask(BuildContext context, TaskProvider taskProvider, Task task) async {
    await taskProvider.completeTask(task.id);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" completed!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              // TODO: Implement undo functionality
            },
          ),
        ),
      );
    }
  }

  void _deleteTask(BuildContext context, TaskProvider taskProvider, Task task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await taskProvider.deleteTask(task.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" moved to Recently Deleted'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'View',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => context.push('/recently-deleted'),
            ),
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
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.isOverdue;
    final hasDeadlineApproaching = task.hasDeadlineApproaching();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 4 : 1,
      color: isOverdue 
          ? theme.colorScheme.errorContainer.withOpacity(0.3)
          : hasDeadlineApproaching 
              ? theme.colorScheme.secondaryContainer.withOpacity(0.3)
              : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with priority and status
              Row(
                children: [
                  // Priority indicator
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(theme.colorScheme),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Task title
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted 
                            ? theme.colorScheme.onSurfaceVariant 
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Status indicators
                  if (isOverdue) ...[
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                  ] else if (hasDeadlineApproaching) ...[
                    Icon(
                      Icons.schedule,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                  ],
                  
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Task details
              Row(
                children: [
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(theme.colorScheme).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor(theme.colorScheme).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.priority.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getPriorityColor(theme.colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Deadline info
                  if (task.deadline != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: isOverdue 
                          ? theme.colorScheme.error
                          : hasDeadlineApproaching
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDeadline(task.deadline!),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isOverdue 
                            ? theme.colorScheme.error
                            : hasDeadlineApproaching
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isOverdue || hasDeadlineApproaching 
                            ? FontWeight.w600 
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Reason (if available)
              if (task.reason != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.reason!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onComplete != null && !isCompleted)
                    TextButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Priority', task.priority.name.toUpperCase()),
            _buildDetailRow('Status', task.statusDisplayName),
            if (task.reason != null) _buildDetailRow('Reason', task.reason!),
            if (task.deadline != null) 
              _buildDetailRow('Deadline', task.deadline!.toLocal().toString().split('.')[0]),
            _buildDetailRow('Created', task.createdAt.toLocal().toString().split('.')[0]),
            if (task.completedAt != null)
              _buildDetailRow('Completed', task.completedAt!.toLocal().toString().split('.')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      final daysPast = (-difference.inDays);
      if (daysPast == 0) {
        return 'Overdue today';
      } else if (daysPast == 1) {
        return 'Overdue by 1 day';
      } else {
        return 'Overdue by $daysPast days';
      }
    } else {
      final daysLeft = difference.inDays;
      final hoursLeft = difference.inHours;
      
      if (daysLeft == 0) {
        if (hoursLeft <= 1) {
          return 'Due in ${difference.inMinutes} minutes';
        } else {
          return 'Due in $hoursLeft hours';
        }
      } else if (daysLeft == 1) {
        return 'Due tomorrow';
      } else if (daysLeft <= 7) {
        return 'Due in $daysLeft days';
      } else {
        return 'Due ${deadline.day}/${deadline.month}';
      }
    }
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