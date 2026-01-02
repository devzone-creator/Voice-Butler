import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/preset_workflow.dart';
import '../providers/preset_workflow_provider.dart';

class PresetWorkflowsScreen extends StatefulWidget {
  const PresetWorkflowsScreen({super.key});

  @override
  State<PresetWorkflowsScreen> createState() => _PresetWorkflowsScreenState();
}

class _PresetWorkflowsScreenState extends State<PresetWorkflowsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preset Workflows'),
      ),
      body: Consumer<PresetWorkflowProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final workflows = provider.workflows;

          if (workflows.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No workflows available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workflows.length,
            itemBuilder: (context, index) {
              final workflow = workflows[index];
              return _buildWorkflowCard(workflow, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkflowCard(PresetWorkflow workflow, PresetWorkflowProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: workflow.isActive ? Colors.green : Colors.grey,
          child: Icon(
            _getCategoryIcon(workflow.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          workflow.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workflow.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(workflow.categoryDisplayName),
                  backgroundColor: _getCategoryColor(workflow.category),
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${workflow.activeRulesCount}/${workflow.rules.length} rules',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: workflow.isActive,
          onChanged: (value) async {
            try {
              if (value) {
                await provider.activateWorkflow(workflow.id);
              } else {
                await provider.deactivateWorkflow(workflow.id);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      workflow.isActive 
                        ? 'Workflow "${workflow.name}" activated'
                        : 'Workflow "${workflow.name}" deactivated',
                    ),
                    backgroundColor: value ? Colors.green : Colors.orange,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        onTap: () => _showWorkflowDetails(context, workflow),
      ),
    );
  }

  IconData _getCategoryIcon(WorkflowCategory category) {
    switch (category) {
      case WorkflowCategory.productivity:
        return Icons.trending_up;
      case WorkflowCategory.focus:
        return Icons.center_focus_strong;
      case WorkflowCategory.deadlines:
        return Icons.schedule;
      case WorkflowCategory.notifications:
        return Icons.notifications_active;
      case WorkflowCategory.organization:
        return Icons.folder_special;
      case WorkflowCategory.custom:
        return Icons.create;
    }
  }

  Color _getCategoryColor(WorkflowCategory category) {
    switch (category) {
      case WorkflowCategory.productivity:
        return Colors.blue;
      case WorkflowCategory.focus:
        return Colors.purple;
      case WorkflowCategory.deadlines:
        return Colors.orange;
      case WorkflowCategory.notifications:
        return Colors.green;
      case WorkflowCategory.organization:
        return Colors.teal;
      case WorkflowCategory.custom:
        return Colors.grey;
    }
  }

  void _showWorkflowDetails(BuildContext context, PresetWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workflow.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(workflow.description),
              const SizedBox(height: 16),
              Text(
                'Category: ${workflow.categoryDisplayName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Rules: ${workflow.rules.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...workflow.rules.map((rule) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• ${rule.name}'),
              )),
              if (workflow.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tags:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: workflow.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: const TextStyle(fontSize: 12),
                  )).toList(),
                ),
              ],
            ],
          ),
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
}