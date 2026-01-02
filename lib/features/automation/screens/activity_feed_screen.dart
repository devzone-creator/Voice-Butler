import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/activity_log.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  List<ActivityLog> _allLogs = [];
  List<ActivityLog> _filteredLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ActivityType? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = StorageService.instance.getAllActivityLogs();
      setState(() {
        _allLogs = logs;
        _filteredLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterLogs() {
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        // Apply search filter
        final matchesSearch = _searchQuery.isEmpty ||
            log.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (log.taskId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Apply type filter
        final matchesType = _selectedFilter == null || log.type == _selectedFilter;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterLogs();
  }

  void _onFilterChanged(ActivityType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterLogs();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedFilter = null;
      _searchController.clear();
    });
    _filterLogs();
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
            tooltip: 'Refresh',
          ),
          PopupMenuButton<ActivityType?>(
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilter != null ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: 'Filter by type',
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem<ActivityType?>(
                value: null,
                child: Text('All Activities'),
              ),
              ...ActivityType.values.map((type) => PopupMenuItem<ActivityType?>(
                value: type,
                child: Row(
                  children: [
                    Icon(_getTypeIcon(type), size: 16, color: _getTypeColor(type)),
                    const SizedBox(width: 8),
                    Text(_getTypeDisplayName(type)),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  onChanged: _onSearchChanged,
                ),
                
                // Active Filters Display
                if (_selectedFilter != null || _searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Active filters:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (_selectedFilter != null)
                              Chip(
                                label: Text(_getTypeDisplayName(_selectedFilter!)),
                                avatar: Icon(_getTypeIcon(_selectedFilter!), size: 16),
                                onDeleted: () => _onFilterChanged(null),
                                deleteIcon: const Icon(Icons.close, size: 16),
                              ),
                            if (_searchQuery.isNotEmpty)
                              Chip(
                                label: Text('Search: "$_searchQuery"'),
                                onDeleted: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                deleteIcon: const Icon(Icons.close, size: 16),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Activity List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_allLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No activity yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Start using the app to see your activity here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No matching activities', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActivityList() {
    // Group activities by date for better chronological display
    final groupedLogs = <String, List<ActivityLog>>{};
    
    for (final log in _filteredLogs) {
      final dateKey = _getDateKey(log.timestamp);
      groupedLogs.putIfAbsent(dateKey, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedLogs.length,
      itemBuilder: (context, index) {
        final dateKey = groupedLogs.keys.elementAt(index);
        final logsForDate = groupedLogs[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(dateKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            // Activities for this date
            ...logsForDate.map((log) => _buildActivityCard(log)),
            
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(log.type),
          child: Icon(_getTypeIcon(log.type), color: Colors.white, size: 20),
        ),
        title: Text(
          log.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDetailedTimestamp(log.timestamp)),
            if (log.taskId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Task ID: ${log.taskId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (log.metadata.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatMetadata(log.metadata),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (log.isSystemGenerated)
              Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            Text(
              _getTypeDisplayName(log.type),
              style: TextStyle(
                fontSize: 10,
                color: _getTypeColor(log.type),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        isThreeLine: log.taskId != null || log.metadata.isNotEmpty,
      ),
    );
  }

  String _getDateKey(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  String _formatDateHeader(String dateKey) {
    final parts = dateKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _formatDetailedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) return '';
    
    final entries = metadata.entries.take(2).map((e) => '${e.key}: ${e.value}').join(', ');
    return metadata.length > 2 ? '$entries...' : entries;
  }

  String _getTypeDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.taskCreated:
        return 'Created';
      case ActivityType.taskCompleted:
        return 'Completed';
      case ActivityType.taskDeleted:
        return 'Deleted';
      case ActivityType.automationApplied:
        return 'Automation';
      case ActivityType.reminderSent:
        return 'Reminder';
      case ActivityType.errorOccurred:
        return 'Error';
      case ActivityType.cleanupPerformed:
        return 'Cleanup';
      case ActivityType.notificationSent:
        return 'Notification';
      case ActivityType.taskRestored:
        return 'Restored';
      default:
        return 'Activity';
    }
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
}