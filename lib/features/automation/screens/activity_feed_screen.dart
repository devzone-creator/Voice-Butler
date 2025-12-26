import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/activity_log.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = StorageService.instance.getRecentActivityLogs(limit: 100);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No activity yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(log.type),
                          child: Icon(_getTypeIcon(log.type), color: Colors.white),
                        ),
                        title: Text(log.description),
                        subtitle: Text(_formatTimestamp(log.timestamp)),
                        trailing: log.isSystemGenerated
                            ? const Icon(Icons.smart_toy, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }

  Color _getTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.taskCreated:
        return Colors.green;
      case ActivityType.taskCompleted:
        return Colors.blue;
      case ActivityType.taskDeleted:
        return Colors.red;
      case ActivityType.automationApplied:
        return Colors.purple;
      case ActivityType.reminderSent:
        return Colors.orange;
      case ActivityType.errorOccurred:
        return Colors.red;
      case ActivityType.cleanupPerformed:
        return Colors.grey;
      case ActivityType.notificationSent:
        return Colors.orange;
      case ActivityType.taskRestored:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.taskCreated:
        return Icons.add_task;
      case ActivityType.taskCompleted:
        return Icons.check_circle;
      case ActivityType.taskDeleted:
        return Icons.delete;
      case ActivityType.automationApplied:
        return Icons.auto_awesome;
      case ActivityType.reminderSent:
        return Icons.notifications;
      case ActivityType.errorOccurred:
        return Icons.error;
      case ActivityType.cleanupPerformed:
        return Icons.cleaning_services;
      case ActivityType.notificationSent:
        return Icons.notifications;
      case ActivityType.taskRestored:
        return Icons.restore;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}