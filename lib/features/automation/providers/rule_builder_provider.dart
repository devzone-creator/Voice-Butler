import 'package:flutter/foundation.dart';
import '../../../core/models/automation_rule.dart';
import '../../../core/services/storage_service.dart';

class RuleBuilderProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;

  // Rule properties
  String _ruleName = '';
  String _ruleDescription = '';
  RuleTrigger? _selectedTrigger;
  List<RuleCondition> _conditions = [];
  List<RuleAction> _actions = [];
  
  // Validation
  final List<String> _validationErrors = [];
  
  // Getters
  String get ruleName => _ruleName;
  String get ruleDescription => _ruleDescription;
  RuleTrigger? get selectedTrigger => _selectedTrigger;
  List<RuleCondition> get conditions => List.unmodifiable(_conditions);
  List<RuleAction> get actions => List.unmodifiable(_actions);
  List<String> get validationErrors => List.unmodifiable(_validationErrors);
  
  bool get isRuleValid {
    _validateRule();
    return _validationErrors.isEmpty;
  }

  /// Sets the rule name
  void setRuleName(String name) {
    _ruleName = name.trim();
    _validateRule();
    notifyListeners();
  }

  /// Sets the rule description
  void setRuleDescription(String description) {
    _ruleDescription = description.trim();
    notifyListeners();
  }

  /// Sets the trigger
  void setTrigger(RuleTrigger? trigger) {
    _selectedTrigger = trigger;
    _validateRule();
    notifyListeners();
  }

  /// Adds a condition
  void addCondition(RuleCondition condition) {
    _conditions.add(condition);
    _validateRule();
    notifyListeners();
  }

  /// Removes a condition at the specified index
  void removeCondition(int index) {
    if (index >= 0 && index < _conditions.length) {
      _conditions.removeAt(index);
      _validateRule();
      notifyListeners();
    }
  }

  /// Adds an action
  void addAction(RuleAction action) {
    _actions.add(action);
    _validateRule();
    notifyListeners();
  }

  /// Removes an action at the specified index
  void removeAction(int index) {
    if (index >= 0 && index < _actions.length) {
      _actions.removeAt(index);
      _validateRule();
      notifyListeners();
    }
  }

  /// Loads an existing rule for editing
  void loadExistingRule(AutomationRule rule) {
    _ruleName = rule.name;
    _ruleDescription = rule.description ?? '';
    _selectedTrigger = rule.trigger;
    _conditions = List.from(rule.conditions);
    _actions = List.from(rule.actions);
    _validateRule();
    notifyListeners();
  }

  /// Resets the rule builder to empty state
  void resetRule() {
    _ruleName = '';
    _ruleDescription = '';
    _selectedTrigger = null;
    _conditions.clear();
    _actions.clear();
    _validationErrors.clear();
    notifyListeners();
  }

  /// Validates the current rule configuration
  void _validateRule() {
    _validationErrors.clear();

    // Validate rule name
    if (_ruleName.isEmpty) {
      _validationErrors.add('Rule name is required');
    } else if (_ruleName.length < 3) {
      _validationErrors.add('Rule name must be at least 3 characters long');
    } else if (_ruleName.length > 100) {
      _validationErrors.add('Rule name must be less than 100 characters');
    }

    // Validate trigger
    if (_selectedTrigger == null) {
      _validationErrors.add('A trigger must be selected');
    }

    // Validate actions
    if (_actions.isEmpty) {
      _validationErrors.add('At least one action is required');
    }

    // Validate conditions
    for (int i = 0; i < _conditions.length; i++) {
      final condition = _conditions[i];
      final conditionErrors = _validateCondition(condition);
      for (final error in conditionErrors) {
        _validationErrors.add('Condition ${i + 1}: $error');
      }
    }

    // Validate actions
    for (int i = 0; i < _actions.length; i++) {
      final action = _actions[i];
      final actionErrors = _validateAction(action);
      for (final error in actionErrors) {
        _validationErrors.add('Action ${i + 1}: $error');
      }
    }

    // Validate rule logic
    _validateRuleLogic();
  }

  /// Validates a single condition
  List<String> _validateCondition(RuleCondition condition) {
    final errors = <String>[];

    if (condition.value.isEmpty) {
      errors.add('Value cannot be empty');
      return errors;
    }

    switch (condition.type) {
      case RuleConditionType.priorityEquals:
        if (!['low', 'medium', 'high'].contains(condition.value.toLowerCase())) {
          errors.add('Priority must be low, medium, or high');
        }
        break;
      case RuleConditionType.deadlineWithin:
      case RuleConditionType.createdWithin:
        final hours = int.tryParse(condition.value);
        if (hours == null || hours <= 0 || hours > 8760) { // Max 1 year
          errors.add('Hours must be a positive number between 1 and 8760');
        }
        break;
      case RuleConditionType.titleContains:
      case RuleConditionType.reasonContains:
        if (condition.value.length < 2) {
          errors.add('Search text must be at least 2 characters');
        }
        break;
      case RuleConditionType.statusEquals:
        if (!['pending', 'completed'].contains(condition.value.toLowerCase())) {
          errors.add('Status must be pending or completed');
        }
        break;
      case RuleConditionType.hasDeadline:
      case RuleConditionType.hasReason:
        if (!['true', 'false'].contains(condition.value.toLowerCase())) {
          errors.add('Value must be true or false');
        }
        break;
    }

    return errors;
  }

  /// Validates a single action
  List<String> _validateAction(RuleAction action) {
    final errors = <String>[];

    switch (action.type) {
      case RuleActionType.sendNotification:
        if (action.parameters['title']?.isEmpty != false) {
          errors.add('Notification title is required');
        }
        if (action.parameters['message']?.isEmpty != false) {
          errors.add('Notification message is required');
        }
        break;
      case RuleActionType.sendReminder:
        if (action.parameters['message']?.isEmpty != false) {
          errors.add('Reminder message is required');
        }
        final delayStr = action.parameters['delayMinutes'];
        if (delayStr?.isEmpty != false) {
          errors.add('Reminder delay is required');
        } else {
          final delay = int.tryParse(delayStr!);
          if (delay == null || delay <= 0 || delay > 10080) { // Max 1 week
            errors.add('Reminder delay must be between 1 and 10080 minutes');
          }
        }
        break;
      case RuleActionType.changePriority:
        final priority = action.parameters['priority'];
        if (priority?.isEmpty != false) {
          errors.add('New priority is required');
        } else if (!['low', 'medium', 'high'].contains(priority!.toLowerCase())) {
          errors.add('Priority must be low, medium, or high');
        }
        break;
      case RuleActionType.logActivity:
        if (action.parameters['message']?.isEmpty != false) {
          errors.add('Log message is required');
        }
        break;
      case RuleActionType.addToFocusMode:
      case RuleActionType.scheduleFollowUp:
      case RuleActionType.sendEmail:
      case RuleActionType.createSubtask:
        // These actions don't require additional validation
        break;
    }

    return errors;
  }

  /// Validates the overall rule logic
  void _validateRuleLogic() {
    if (_selectedTrigger == null) return;

    // Check for logical inconsistencies
    switch (_selectedTrigger!) {
      case RuleTrigger.taskCompleted:
        // Check if trying to change priority of completed task
        final hasPriorityChange = _actions.any((action) => 
            action.type == RuleActionType.changePriority);
        if (hasPriorityChange) {
          _validationErrors.add('Cannot change priority of completed tasks');
        }
        break;
      case RuleTrigger.taskDeleted:
        // Check if trying to modify deleted task
        final hasModificationAction = _actions.any((action) => 
            action.type == RuleActionType.changePriority ||
            action.type == RuleActionType.addToFocusMode);
        if (hasModificationAction) {
          _validationErrors.add('Cannot modify deleted tasks');
        }
        break;
      case RuleTrigger.deadlineApproaching:
        // Ensure there's a deadline condition if using deadline trigger
        final hasDeadlineCondition = _conditions.any((condition) =>
            condition.type == RuleConditionType.hasDeadline ||
            condition.type == RuleConditionType.deadlineWithin);
        if (!hasDeadlineCondition) {
          _validationErrors.add('Deadline trigger should include deadline-related conditions');
        }
        break;
      default:
        break;
    }

    // Check for duplicate actions
    final actionTypes = _actions.map((action) => action.type).toList();
    final uniqueActionTypes = actionTypes.toSet();
    if (actionTypes.length != uniqueActionTypes.length) {
      _validationErrors.add('Duplicate actions are not allowed');
    }

    // Check for conflicting conditions
    _validateConditionConflicts();
  }

  /// Validates for conflicting conditions
  void _validateConditionConflicts() {
    final priorityConditions = _conditions.where((c) => 
        c.type == RuleConditionType.priorityEquals).toList();
    if (priorityConditions.length > 1) {
      final priorities = priorityConditions.map((c) => c.value).toSet();
      if (priorities.length > 1) {
        _validationErrors.add('Conflicting priority conditions detected');
      }
    }

    final statusConditions = _conditions.where((c) => 
        c.type == RuleConditionType.statusEquals).toList();
    if (statusConditions.length > 1) {
      final statuses = statusConditions.map((c) => c.value).toSet();
      if (statuses.length > 1) {
        _validationErrors.add('Conflicting status conditions detected');
      }
    }
  }

  /// Builds the automation rule from current state
  AutomationRule buildRule() {
    if (!isRuleValid) {
      throw StateError('Cannot build invalid rule');
    }

    return AutomationRule.create(
      name: _ruleName,
      trigger: _selectedTrigger!,
      conditions: List.from(_conditions),
      actions: List.from(_actions),
      description: _ruleDescription.isNotEmpty ? _ruleDescription : null,
      isPreset: false,
    );
  }

  /// Saves the rule to storage
  Future<void> saveRule(AutomationRule rule) async {
    try {
      await _storageService.storeAutomationRule(rule);
      
      if (kDebugMode) {
        print('Rule saved successfully: ${rule.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save rule: $e');
      }
      rethrow;
    }
  }

  /// Tests the rule against sample data
  Map<String, dynamic> testRule(AutomationRule rule, Map<String, dynamic> sampleData) {
    final results = <String, dynamic>{
      'ruleName': rule.name,
      'triggerMatches': false,
      'conditionsMatch': false,
      'wouldExecute': false,
      'matchedConditions': <String>[],
      'failedConditions': <String>[],
      'actionsToExecute': <String>[],
    };

    // Test trigger (simplified - in real implementation this would be more complex)
    results['triggerMatches'] = true; // Assume trigger matches for testing

    // Test conditions
    if (rule.conditions.isEmpty) {
      results['conditionsMatch'] = true;
    } else {
      int matchedCount = 0;
      for (final condition in rule.conditions) {
        final matches = _testCondition(condition, sampleData);
        if (matches) {
          matchedCount++;
          (results['matchedConditions'] as List<String>).add(
            '${condition.typeDisplayName}: ${condition.value}'
          );
        } else {
          (results['failedConditions'] as List<String>).add(
            '${condition.typeDisplayName}: ${condition.value}'
          );
        }
      }
      results['conditionsMatch'] = matchedCount == rule.conditions.length;
    }

    // Determine if rule would execute
    results['wouldExecute'] = results['triggerMatches'] && results['conditionsMatch'];

    // List actions that would execute
    if (results['wouldExecute']) {
      (results['actionsToExecute'] as List<String>).addAll(
        rule.actions.map((action) => action.typeDisplayName)
      );
    }

    return results;
  }

  /// Tests a single condition against sample data
  bool _testCondition(RuleCondition condition, Map<String, dynamic> sampleData) {
    switch (condition.type) {
      case RuleConditionType.priorityEquals:
        return sampleData['priority']?.toString().toLowerCase() == 
               condition.value.toLowerCase();
      case RuleConditionType.titleContains:
        return sampleData['title']?.toString().toLowerCase().contains(
               condition.value.toLowerCase()) == true;
      case RuleConditionType.reasonContains:
        return sampleData['reason']?.toString().toLowerCase().contains(
               condition.value.toLowerCase()) == true;
      case RuleConditionType.statusEquals:
        return sampleData['status']?.toString().toLowerCase() == 
               condition.value.toLowerCase();
      case RuleConditionType.hasDeadline:
        final hasDeadline = sampleData['deadline'] != null;
        return hasDeadline.toString().toLowerCase() == condition.value.toLowerCase();
      case RuleConditionType.hasReason:
        final hasReason = sampleData['reason']?.toString().isNotEmpty == true;
        return hasReason.toString().toLowerCase() == condition.value.toLowerCase();
      case RuleConditionType.deadlineWithin:
      case RuleConditionType.createdWithin:
        // Simplified implementation - would need actual date comparison
        return true;
    }
  }

  /// Gets rule complexity score (for UI feedback)
  int getRuleComplexity() {
    int complexity = 1; // Base complexity
    
    complexity += _conditions.length; // Each condition adds complexity
    complexity += _actions.length; // Each action adds complexity
    
    // Certain triggers are more complex
    if (_selectedTrigger == RuleTrigger.dailyReview || 
        _selectedTrigger == RuleTrigger.weeklyReview) {
      complexity += 2;
    }
    
    return complexity;
  }

  /// Gets rule performance impact estimate
  String getPerformanceImpact() {
    final complexity = getRuleComplexity();
    
    if (complexity <= 3) {
      return 'Low';
    } else if (complexity <= 6) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  /// Gets suggested improvements for the rule
  List<String> getSuggestedImprovements() {
    final suggestions = <String>[];
    
    if (_conditions.isEmpty) {
      suggestions.add('Consider adding conditions to make the rule more specific');
    }
    
    if (_conditions.length > 5) {
      suggestions.add('Too many conditions may make the rule hard to understand');
    }
    
    if (_actions.length > 3) {
      suggestions.add('Consider splitting complex rules into multiple simpler rules');
    }
    
    final hasNotificationAction = _actions.any((action) => 
        action.type == RuleActionType.sendNotification);
    final hasReminderAction = _actions.any((action) => 
        action.type == RuleActionType.sendReminder);
    
    if (hasNotificationAction && hasReminderAction) {
      suggestions.add('Having both notifications and reminders may be redundant');
    }
    
    return suggestions;
  }
}