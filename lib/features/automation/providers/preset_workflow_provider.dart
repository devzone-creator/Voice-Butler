import 'package:flutter/foundation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/preset_workflow.dart';
import '../../../core/models/automation_rule.dart';
import '../../../core/models/activity_log.dart';
import '../../../core/models/task.dart';
import 'automation_provider.dart';

class PresetWorkflowProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  final AutomationProvider _automationProvider;
  
  List<PresetWorkflow> _workflows = [];
  bool _isInitialized = false;

  List<PresetWorkflow> get workflows => _workflows;
  List<PresetWorkflow> get activeWorkflows => _workflows.where((w) => w.isActive).toList();
  List<PresetWorkflow> get builtInWorkflows => _workflows.where((w) => w.isBuiltIn).toList();
  List<PresetWorkflow> get customWorkflows => _workflows.where((w) => !w.isBuiltIn).toList();
  bool get isInitialized => _isInitialized;

  PresetWorkflowProvider(this._automationProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadWorkflows();
      await _ensureBuiltInWorkflows();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Failed to initialize preset workflows: $e');
    }
  }

  Future<void> _loadWorkflows() async {
    _workflows = _storageService.getAllPresetWorkflows();
  }

  Future<void> _ensureBuiltInWorkflows() async {
    final existingBuiltInIds = _workflows
        .where((w) => w.isBuiltIn)
        .map((w) => w.name)
        .toSet();

    for (final builtInWorkflow in PresetWorkflow.builtInWorkflows) {
      if (!existingBuiltInIds.contains(builtInWorkflow.name)) {
        await addWorkflow(builtInWorkflow);
      }
    }
  }

  /// Adds a new preset workflow
  Future<void> addWorkflow(PresetWorkflow workflow) async {
    await _storageService.storePresetWorkflow(workflow);
    _workflows.add(workflow);
    notifyListeners();
  }

  /// Updates an existing preset workflow
  Future<void> updateWorkflow(PresetWorkflow workflow) async {
    await _storageService.storePresetWorkflow(workflow);
    final index = _workflows.indexWhere((w) => w.id == workflow.id);
    if (index != -1) {
      _workflows[index] = workflow;
      notifyListeners();
    }
  }

  /// Deletes a preset workflow (only custom workflows can be deleted)
  Future<void> deleteWorkflow(String workflowId) async {
    final workflow = _workflows.firstWhere((w) => w.id == workflowId);
    if (workflow.isBuiltIn) {
      throw Exception('Built-in workflows cannot be deleted');
    }

    await _storageService.deletePresetWorkflow(workflowId);
    _workflows.removeWhere((w) => w.id == workflowId);
    notifyListeners();
  }

  /// Activates a preset workflow and applies all its rules
  Future<void> activateWorkflow(String workflowId) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);
      final activatedWorkflow = workflow.activate();
      
      // Update the workflow
      await updateWorkflow(activatedWorkflow);
      
      // Apply all rules from the workflow to the automation provider
      await _applyWorkflowRules(activatedWorkflow);
      
      // Log the workflow activation
      final log = ActivityLog.create(
        taskId: 'system',
        type: ActivityType.workflowActivated,
        description: 'Activated preset workflow "${workflow.name}" with ${workflow.rules.length} rules',
        metadata: {
          'workflowId': workflow.id,
          'workflowName': workflow.name,
          'workflowCategory': workflow.category.name,
          'rulesCount': workflow.rules.length,
          'activeRulesCount': workflow.activeRulesCount,
        },
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Activated workflow: ${workflow.name} with ${workflow.rules.length} rules');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to activate workflow: $e');
      }
      rethrow;
    }
  }

  /// Deactivates a preset workflow and removes its rules
  Future<void> deactivateWorkflow(String workflowId) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);
      final deactivatedWorkflow = workflow.deactivate();
      
      // Update the workflow
      await updateWorkflow(deactivatedWorkflow);
      
      // Remove workflow rules from the automation provider
      await _removeWorkflowRules(workflow);
      
      // Log the workflow deactivation
      final log = ActivityLog.create(
        taskId: 'system',
        type: ActivityType.workflowDeactivated,
        description: 'Deactivated preset workflow "${workflow.name}"',
        metadata: {
          'workflowId': workflow.id,
          'workflowName': workflow.name,
          'workflowCategory': workflow.category.name,
          'rulesCount': workflow.rules.length,
        },
      );
      await _storageService.storeActivityLog(log);
      
      if (kDebugMode) {
        print('Deactivated workflow: ${workflow.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to deactivate workflow: $e');
      }
      rethrow;
    }
  }

  /// Applies all rules from a workflow to the automation provider
  Future<void> _applyWorkflowRules(PresetWorkflow workflow) async {
    for (final rule in workflow.rules) {
      if (rule.isActive) {
        // Check if rule already exists to avoid duplicates
        final existingRules = _automationProvider.rules;
        final ruleExists = existingRules.any((existingRule) => 
          existingRule.name == rule.name && existingRule.isPreset);
        
        if (!ruleExists) {
          await _automationProvider.addRule(rule);
        }
      }
    }
  }

  /// Removes workflow rules from the automation provider
  Future<void> _removeWorkflowRules(PresetWorkflow workflow) async {
    for (final rule in workflow.rules) {
      // Find and remove matching preset rules
      final existingRules = _automationProvider.rules;
      final matchingRules = existingRules.where((existingRule) => 
        existingRule.name == rule.name && existingRule.isPreset);
      
      for (final matchingRule in matchingRules) {
        await _automationProvider.deleteRule(matchingRule.id);
      }
    }
  }

  /// Executes a preset workflow for a specific task
  Future<void> executeWorkflowForTask(String workflowId, Task task) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);
      
      if (!workflow.isActive) {
        throw Exception('Workflow "${workflow.name}" is not active');
      }

      int executedRulesCount = 0;
      final executedActions = <String>[];

      // Execute each rule in the workflow
      for (final rule in workflow.rules) {
        if (rule.isActive) {
          // Check if rule should trigger for this task
          if (_shouldTriggerRule(rule, task)) {
            await _executeRule(rule, task);
            executedRulesCount++;
            executedActions.addAll(rule.actions.map((a) => a.typeDisplayName));
          }
        }
      }

      // Log the workflow execution
      final log = ActivityLog.create(
        taskId: task.id,
        type: ActivityType.workflowExecuted,
        description: 'Executed preset workflow "${workflow.name}" for task "${task.title}": $executedRulesCount rules triggered',
        metadata: {
          'workflowId': workflow.id,
          'workflowName': workflow.name,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
          'executedRulesCount': executedRulesCount,
          'totalRulesCount': workflow.rules.length,
          'executedActions': executedActions,
        },
      );
      await _storageService.storeActivityLog(log);

      if (kDebugMode) {
        print('Executed workflow "${workflow.name}" for task "${task.title}": $executedRulesCount rules triggered');
      }
    } catch (e) {
      // Log workflow execution failure
      final errorLog = ActivityLog.errorOccurred(
        taskId: task.id,
        errorMessage: 'Failed to execute preset workflow: $e',
        additionalMetadata: {
          'workflowId': workflowId,
          'taskTitle': task.title,
          'taskPriority': task.priority.name,
        },
      );
      await _storageService.storeActivityLog(errorLog);
      
      if (kDebugMode) {
        print('Failed to execute workflow for task: $e');
      }
      rethrow;
    }
  }

  /// Checks if a rule should trigger for a given task
  bool _shouldTriggerRule(AutomationRule rule, Task task) {
    // Check trigger
    switch (rule.trigger) {
      case RuleTrigger.taskCreated:
        // Always trigger for new tasks
        break;
      case RuleTrigger.deadlineApproaching:
        if (!task.hasDeadlineApproaching()) return false;
        break;
      case RuleTrigger.taskCompleted:
        if (task.status != TaskStatus.completed) return false;
        break;
      case RuleTrigger.taskDeleted:
        if (task.status != TaskStatus.softDeleted) return false;
        break;
      default:
        break;
    }

    // Check conditions
    for (final condition in rule.conditions) {
      if (!_evaluateCondition(condition, task)) {
        return false;
      }
    }

    return true;
  }

  /// Evaluates a rule condition against a task
  bool _evaluateCondition(RuleCondition condition, Task task) {
    switch (condition.type) {
      case RuleConditionType.priorityEquals:
        final priority = TaskPriority.values.firstWhere(
          (p) => p.name == condition.value,
          orElse: () => TaskPriority.medium,
        );
        return task.priority == priority;
      case RuleConditionType.hasDeadline:
        return task.deadline != null;
      case RuleConditionType.titleContains:
        return task.title.toLowerCase().contains(condition.value.toLowerCase());
      case RuleConditionType.deadlineWithin:
        if (task.deadline == null) return false;
        final hours = int.tryParse(condition.value) ?? 24;
        return task.deadline!.difference(DateTime.now()).inHours <= hours;
      default:
        return false;
    }
  }

  /// Executes a rule for a task
  Future<void> _executeRule(AutomationRule rule, Task task) async {
    // Delegate to automation provider for rule execution
    await _automationProvider.applyAutomationRules(task);
  }

  /// Gets workflows by category
  List<PresetWorkflow> getWorkflowsByCategory(WorkflowCategory category) {
    return _workflows.where((w) => w.category == category).toList();
  }

  /// Gets workflow by ID
  PresetWorkflow? getWorkflowById(String workflowId) {
    try {
      return _workflows.firstWhere((w) => w.id == workflowId);
    } catch (e) {
      return null;
    }
  }

  /// Creates a custom workflow from existing automation rules
  Future<PresetWorkflow> createCustomWorkflow({
    required String name,
    required String description,
    required WorkflowCategory category,
    required List<String> ruleIds,
    String? iconName,
    List<String> tags = const [],
  }) async {
    try {
      // Get the selected rules
      final allRules = _automationProvider.rules;
      final selectedRules = allRules.where((rule) => ruleIds.contains(rule.id)).toList();

      if (selectedRules.isEmpty) {
        throw Exception('No valid rules selected for workflow');
      }

      // Create the custom workflow
      final workflow = PresetWorkflow.create(
        name: name,
        description: description,
        category: category,
        rules: selectedRules,
        iconName: iconName,
        tags: tags,
        isBuiltIn: false,
      );

      await addWorkflow(workflow);

      // Log the custom workflow creation
      final log = ActivityLog.create(
        taskId: 'system',
        type: ActivityType.workflowCreated,
        description: 'Created custom workflow "$name" with ${selectedRules.length} rules',
        metadata: {
          'workflowId': workflow.id,
          'workflowName': name,
          'workflowCategory': category.name,
          'rulesCount': selectedRules.length,
          'ruleIds': ruleIds,
        },
      );
      await _storageService.storeActivityLog(log);

      if (kDebugMode) {
        print('Created custom workflow: $name with ${selectedRules.length} rules');
      }

      return workflow;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create custom workflow: $e');
      }
      rethrow;
    }
  }

  /// Gets workflow statistics
  Map<String, dynamic> getWorkflowStatistics() {
    final totalWorkflows = _workflows.length;
    final activeWorkflows = _workflows.where((w) => w.isActive).length;
    final builtInWorkflows = _workflows.where((w) => w.isBuiltIn).length;
    final customWorkflows = _workflows.where((w) => !w.isBuiltIn).length;
    
    final categoryCounts = <String, int>{};
    for (final category in WorkflowCategory.values) {
      categoryCounts[category.name] = _workflows.where((w) => w.category == category).length;
    }

    return {
      'totalWorkflows': totalWorkflows,
      'activeWorkflows': activeWorkflows,
      'builtInWorkflows': builtInWorkflows,
      'customWorkflows': customWorkflows,
      'categoryCounts': categoryCounts,
    };
  }

  /// Refreshes workflows from storage
  Future<void> refresh() async {
    await _loadWorkflows();
    notifyListeners();
  }
}