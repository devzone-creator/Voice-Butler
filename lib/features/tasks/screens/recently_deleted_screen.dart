import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../../../core/models/task.dart';

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restore_all',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore All'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Delete All Permanently'),
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(context, value),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final deletedTasks = taskProvider.softDeletedTasks;

          if (deletedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline, 
                    size: 64, 
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deleted tasks', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleted tasks will appear here and be automatically removed after 7 days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Sort by deletion date (most recent first)
          final sortedTasks = List<Task>.from(deletedTasks)
            ..sort((a, b) => (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));

          return Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tasks are automatically deleted after 7 days. You can restore or permanently delete them before then.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    final daysUntilAutoDelete = _getDaysUntilAutoDelete(task);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with title and auto-delete warning
                            Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (daysUntilAutoDelete <= 2)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      daysUntilAutoDelete == 0 
                                          ? 'Deletes today'
                                          : 'Deletes in $daysUntilAutoDelete days',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Task details
                            if (task.reason != null) ...[
                              Text(
                                task.reason!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Metadata
                            Row(
                              children: [
                                Text(
                                  'Priority: ${task.priority.name.toUpperCase()}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Deleted: ${_formatDeletedDate(task.deletedAt)}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _restoreTask(context, taskProvider, task),
                                  icon: const Icon(Icons.restore, size: 16),
                                  label: const Text('Restore'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmPermanentDelete(context, task, taskProvider),
                                  icon: const Icon(Icons.delete_forever, size: 16),
                                  label: const Text('Delete Forever'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final taskProvider = context.read<TaskProvider>();
    
    switch (action) {
      case 'restore_all':
        _confirmRestoreAll(context, taskProvider);
        break;
      case 'delete_all':
        _confirmDeleteAll(context, taskProvider);
        break;
    }
  }

  void _confirmRestoreAll(BuildContext context, TaskProvider taskProvider) {
    final deletedTasks = taskProvider.softDeletedTasks;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore All Tasks'),
        content: Text('Are you sure you want to restore all ${deletedTasks.length} deleted tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              for (final task in deletedTasks) {
                await taskProvider.restoreTask(task.id);
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restored ${deletedTasks.length} tasks'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            },
            child: const Text('Restore All'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, TaskProvider taskProvider) {
    final deletedTasks = taskProvider.softDeletedTasks;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Permanently'),
        content: Text('Are you sure you want to permanently delete all ${deletedTasks.length} tasks? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              for (final task in deletedTasks) {
                await taskProvider.permanentlyDeleteTask(task.id);
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permanently deleted ${deletedTasks.length} tasks'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _restoreTask(BuildContext context, TaskProvider taskProvider, Task task) async {
    await taskProvider.restoreTask(task.id);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" restored'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _confirmPermanentDelete(BuildContext context, Task task, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text('Are you sure you want to permanently delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await taskProvider.permanentlyDeleteTask(task.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${task.title}" permanently deleted'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  int _getDaysUntilAutoDelete(Task task) {
    if (task.deletedAt == null) return 7;
    
    final daysSinceDeleted = DateTime.now().difference(task.deletedAt!).inDays;
    return (7 - daysSinceDeleted).clamp(0, 7);
  }

  String _formatDeletedDate(DateTime? deletedAt) {
    if (deletedAt == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(deletedAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}