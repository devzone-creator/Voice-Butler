import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/automation_rule.dart';
import '../providers/rule_builder_provider.dart';

class RuleBuilderScreen extends StatefulWidget {
  final AutomationRule? existingRule;

  const RuleBuilderScreen({
    super.key,
    this.existingRule,
  });

  @override
  State<RuleBuilderScreen> createState() => _RuleBuilderScreenState();
}

class _RuleBuilderScreenState extends State<RuleBuilderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RuleBuilderProvider>();
      if (widget.existingRule != null) {
        provider.loadExistingRule(widget.existingRule!);
      } else {
        provider.resetRule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRule != null ? 'Edit Rule' : 'Create Rule'),
        actions: [
          Consumer<RuleBuilderProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.preview),
                onPressed: provider.isRuleValid ? () => _showPreview(context, provider) : null,
                tooltip: 'Preview Rule',
              );
            },
          ),
        ],
      ),
      body: Consumer<RuleBuilderProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rule Name
                _buildRuleNameSection(provider),
                const SizedBox(height: 24),
                
                // Rule Description
                _buildRuleDescriptionSection(provider),
                const SizedBox(height: 24),
                
                // Trigger Section
                _buildTriggerSection(provider),
                const SizedBox(height: 24),
                
                // Conditions Section
                _buildConditionsSection(provider),
                const SizedBox(height: 24),
                
                // Actions Section
                _buildActionsSection(provider),
                const SizedBox(height: 24),
                
                // Validation Messages
                if (provider.validationErrors.isNotEmpty)
                  _buildValidationSection(provider),
                
                const SizedBox(height: 32),
                
                // Save Button
                _buildSaveButton(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRuleNameSection(RuleBuilderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rule Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: provider.ruleName,
              decoration: const InputDecoration(
                hintText: 'Enter a descriptive name for your rule',
                border: OutlineInputBorder(),
              ),
              onChanged: provider.setRuleName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleDescriptionSection(RuleBuilderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: provider.ruleDescription,
              decoration: const InputDecoration(
                hintText: 'Describe what this rule does',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: provider.setRuleDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerSection(RuleBuilderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trigger',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'When should this rule activate?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RuleTrigger>(
              initialValue: provider.selectedTrigger,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a trigger',
              ),
              items: RuleTrigger.values.map((trigger) {
                return DropdownMenuItem(
                  value: trigger,
                  child: Text(_getTriggerDisplayName(trigger)),
                );
              }).toList(),
              onChanged: provider.setTrigger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection(RuleBuilderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conditions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddConditionDialog(context, provider),
                  tooltip: 'Add Condition',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'What conditions must be met? (Optional)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (provider.conditions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No conditions added. Rule will trigger for all matching events.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...provider.conditions.asMap().entries.map((entry) {
                final index = entry.key;
                final condition = entry.value;
                return _buildConditionTile(provider, condition, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionTile(RuleBuilderProvider provider, RuleCondition condition, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(_getConditionDisplayText(condition)),
        subtitle: Text('${condition.typeDisplayName}: ${condition.value}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => provider.removeCondition(index),
        ),
      ),
    );
  }

  Widget _buildActionsSection(RuleBuilderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddActionDialog(context, provider),
                  tooltip: 'Add Action',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'What should happen when the rule triggers?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (provider.actions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'At least one action is required.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              ...provider.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return _buildActionTile(provider, action, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(RuleBuilderProvider provider, RuleAction action, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(action.typeDisplayName),
        subtitle: Text(_getActionDisplayText(action)),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => provider.removeAction(index),
        ),
      ),
    );
  }

  Widget _buildValidationSection(RuleBuilderProvider provider) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Validation Errors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...provider.validationErrors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $error',
                style: const TextStyle(color: Colors.red),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(RuleBuilderProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: provider.isRuleValid ? () => _saveRule(provider) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.existingRule != null ? 'Update Rule' : 'Create Rule',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _showAddConditionDialog(BuildContext context, RuleBuilderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddConditionDialog(
        onConditionAdded: provider.addCondition,
      ),
    );
  }

  void _showAddActionDialog(BuildContext context, RuleBuilderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddActionDialog(
        onActionAdded: provider.addAction,
      ),
    );
  }

  void _showPreview(BuildContext context, RuleBuilderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => RulePreviewDialog(
        rule: provider.buildRule(),
      ),
    );
  }

  Future<void> _saveRule(RuleBuilderProvider provider) async {
    try {
      final rule = provider.buildRule();
      await provider.saveRule(rule);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRule != null 
                ? 'Rule updated successfully!' 
                : 'Rule created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(rule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving rule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTriggerDisplayName(RuleTrigger trigger) {
    switch (trigger) {
      case RuleTrigger.taskCreated:
        return 'Task Created';
      case RuleTrigger.deadlineApproaching:
        return 'Deadline Approaching';
      case RuleTrigger.taskCompleted:
        return 'Task Completed';
      case RuleTrigger.taskDeleted:
        return 'Task Deleted';
      case RuleTrigger.highPriorityTask:
        return 'High Priority Task';
      case RuleTrigger.taskOverdue:
        return 'Task Overdue';
      case RuleTrigger.dailyReview:
        return 'Daily Review';
      case RuleTrigger.weeklyReview:
        return 'Weekly Review';
    }
  }

  String _getConditionDisplayText(RuleCondition condition) {
    return '${condition.typeDisplayName} ${condition.operator ?? ''} ${condition.value}';
  }

  String _getActionDisplayText(RuleAction action) {
    switch (action.type) {
      case RuleActionType.sendNotification:
        return action.parameters['title'] ?? 'Notification';
      case RuleActionType.sendReminder:
        return 'Reminder: ${action.parameters['message'] ?? 'Default message'}';
      case RuleActionType.changePriority:
        return 'Change to ${action.parameters['priority'] ?? 'unknown'} priority';
      case RuleActionType.addToFocusMode:
        return 'Add to focus mode';
      case RuleActionType.logActivity:
        return 'Log: ${action.parameters['message'] ?? 'Activity logged'}';
      default:
        return action.typeDisplayName;
    }
  }
}

// Add Condition Dialog
class AddConditionDialog extends StatefulWidget {
  final Function(RuleCondition) onConditionAdded;

  const AddConditionDialog({
    super.key,
    required this.onConditionAdded,
  });

  @override
  State<AddConditionDialog> createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<AddConditionDialog> {
  RuleConditionType? selectedType;
  String value = '';
  String? operator;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Condition'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<RuleConditionType>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              labelText: 'Condition Type',
              border: OutlineInputBorder(),
            ),
            items: RuleConditionType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getConditionTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (type) {
              setState(() {
                selectedType = type;
                operator = _getDefaultOperator(type);
              });
            },
          ),
          const SizedBox(height: 16),
          if (selectedType != null) ...[
            TextFormField(
              decoration: InputDecoration(
                labelText: _getValueLabel(selectedType!),
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => value = val,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedType != null && value.isNotEmpty
              ? () {
                  final condition = RuleCondition(
                    type: selectedType!,
                    value: value,
                    operator: operator,
                  );
                  widget.onConditionAdded(condition);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _getConditionTypeDisplayName(RuleConditionType type) {
    switch (type) {
      case RuleConditionType.priorityEquals:
        return 'Priority Equals';
      case RuleConditionType.deadlineWithin:
        return 'Deadline Within';
      case RuleConditionType.titleContains:
        return 'Title Contains';
      case RuleConditionType.reasonContains:
        return 'Reason Contains';
      case RuleConditionType.statusEquals:
        return 'Status Equals';
      case RuleConditionType.createdWithin:
        return 'Created Within';
      case RuleConditionType.hasDeadline:
        return 'Has Deadline';
      case RuleConditionType.hasReason:
        return 'Has Reason';
    }
  }

  String _getValueLabel(RuleConditionType type) {
    switch (type) {
      case RuleConditionType.priorityEquals:
        return 'Priority (low, medium, high)';
      case RuleConditionType.deadlineWithin:
        return 'Hours';
      case RuleConditionType.titleContains:
        return 'Text in title';
      case RuleConditionType.reasonContains:
        return 'Text in reason';
      case RuleConditionType.statusEquals:
        return 'Status (pending, completed)';
      case RuleConditionType.createdWithin:
        return 'Hours';
      case RuleConditionType.hasDeadline:
        return 'true/false';
      case RuleConditionType.hasReason:
        return 'true/false';
    }
  }

  String? _getDefaultOperator(RuleConditionType? type) {
    if (type == null) return null;
    switch (type) {
      case RuleConditionType.priorityEquals:
      case RuleConditionType.statusEquals:
      case RuleConditionType.hasDeadline:
      case RuleConditionType.hasReason:
        return 'equals';
      case RuleConditionType.deadlineWithin:
      case RuleConditionType.createdWithin:
        return 'less_than';
      case RuleConditionType.titleContains:
      case RuleConditionType.reasonContains:
        return 'contains';
    }
  }
}

// Add Action Dialog
class AddActionDialog extends StatefulWidget {
  final Function(RuleAction) onActionAdded;

  const AddActionDialog({
    super.key,
    required this.onActionAdded,
  });

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  RuleActionType? selectedType;
  final Map<String, String> parameters = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<RuleActionType>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Action Type',
                border: OutlineInputBorder(),
              ),
              items: RuleActionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getActionTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  selectedType = type;
                  parameters.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedType != null) ..._buildParameterFields(selectedType!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedType != null && _areParametersValid(selectedType!)
              ? () {
                  final action = RuleAction(
                    type: selectedType!,
                    parameters: Map.from(parameters),
                  );
                  widget.onActionAdded(action);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  List<Widget> _buildParameterFields(RuleActionType type) {
    switch (type) {
      case RuleActionType.sendNotification:
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => parameters['title'] = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => parameters['message'] = value,
          ),
        ];
      case RuleActionType.sendReminder:
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Reminder Message',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => parameters['message'] = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Delay (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => parameters['delayMinutes'] = value,
          ),
        ];
      case RuleActionType.changePriority:
        return [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'New Priority',
              border: OutlineInputBorder(),
            ),
            items: ['low', 'medium', 'high'].map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => parameters['priority'] = value ?? '',
          ),
        ];
      case RuleActionType.logActivity:
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Log Message',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => parameters['message'] = value,
          ),
        ];
      case RuleActionType.addToFocusMode:
      case RuleActionType.scheduleFollowUp:
      case RuleActionType.sendEmail:
      case RuleActionType.createSubtask:
        return [
          const Text('This action requires no additional parameters.'),
        ];
    }
  }

  bool _areParametersValid(RuleActionType type) {
    switch (type) {
      case RuleActionType.sendNotification:
        return parameters['title']?.isNotEmpty == true && 
               parameters['message']?.isNotEmpty == true;
      case RuleActionType.sendReminder:
        return parameters['message']?.isNotEmpty == true && 
               parameters['delayMinutes']?.isNotEmpty == true;
      case RuleActionType.changePriority:
        return parameters['priority']?.isNotEmpty == true;
      case RuleActionType.logActivity:
        return parameters['message']?.isNotEmpty == true;
      case RuleActionType.addToFocusMode:
      case RuleActionType.scheduleFollowUp:
      case RuleActionType.sendEmail:
      case RuleActionType.createSubtask:
        return true;
    }
  }

  String _getActionTypeDisplayName(RuleActionType type) {
    switch (type) {
      case RuleActionType.sendNotification:
        return 'Send Notification';
      case RuleActionType.sendReminder:
        return 'Send Reminder';
      case RuleActionType.changePriority:
        return 'Change Priority';
      case RuleActionType.addToFocusMode:
        return 'Add to Focus Mode';
      case RuleActionType.scheduleFollowUp:
        return 'Schedule Follow-up';
      case RuleActionType.logActivity:
        return 'Log Activity';
      case RuleActionType.sendEmail:
        return 'Send Email';
      case RuleActionType.createSubtask:
        return 'Create Subtask';
    }
  }
}

// Rule Preview Dialog
class RulePreviewDialog extends StatelessWidget {
  final AutomationRule rule;

  const RulePreviewDialog({
    super.key,
    required this.rule,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rule Preview'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rule.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (rule.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(rule.description!),
            ],
            const SizedBox(height: 16),
            const Text(
              'Human-readable description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(rule.humanReadableDescription),
            const SizedBox(height: 16),
            const Text(
              'Technical details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Trigger: ${rule.triggerDisplayName}'),
            if (rule.conditions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Conditions: ${rule.conditions.length}'),
              ...rule.conditions.map((condition) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• ${condition.typeDisplayName}: ${condition.value}'),
              )),
            ],
            const SizedBox(height: 4),
            Text('Actions: ${rule.actions.length}'),
            ...rule.actions.map((action) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• ${action.typeDisplayName}'),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}