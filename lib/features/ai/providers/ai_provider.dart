import 'package:flutter/foundation.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/models/task.dart';

/// Provider for managing AI service state and operations
class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService.instance;
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastError;
  TaskIntentResult? _lastTaskResult;
  AutomationRuleResult? _lastRuleResult;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  bool get hasApiKey => _aiService.hasApiKey;
  String? get lastError => _lastError;
  TaskIntentResult? get lastTaskResult => _lastTaskResult;
  AutomationRuleResult? get lastRuleResult => _lastRuleResult;

  AIProvider() {
    _initialize();
  }

  /// Initializes the AI provider
  Future<void> _initialize() async {
    try {
      _setProcessing(true);
      _clearError();
      
      final success = await _aiService.initialize();
      _isInitialized = success;
      
      if (!success && !_aiService.hasApiKey) {
        _setError('Gemini API key not configured. AI features will be limited.');
      }
    } catch (e) {
      _setError('Failed to initialize AI service: $e');
    } finally {
      _setProcessing(false);
    }
  }

  /// Extracts task intent from natural language text
  Future<TaskIntentResult> extractTaskIntent(String text) async {
    if (text.trim().isEmpty) {
      final result = TaskIntentResult.error('Please provide a task description');
      _lastTaskResult = result;
      notifyListeners();
      return result;
    }

    try {
      _setProcessing(true);
      _clearError();
      
      final result = await _aiService.extractTaskIntent(text);
      _lastTaskResult = result;
      
      if (!result.isSuccess) {
        _setError(result.error ?? 'Failed to extract task intent');
      }
      
      return result;
    } catch (e) {
      final errorResult = TaskIntentResult.error('Unexpected error: $e');
      _lastTaskResult = errorResult;
      _setError('Unexpected error during task extraction: $e');
      return errorResult;
    } finally {
      _setProcessing(false);
    }
  }

  /// Converts natural language to automation rule
  Future<AutomationRuleResult> convertNaturalLanguageRule(String description) async {
    if (description.trim().isEmpty) {
      final result = AutomationRuleResult.error('Please provide a rule description');
      _lastRuleResult = result;
      notifyListeners();
      return result;
    }

    try {
      _setProcessing(true);
      _clearError();
      
      final result = await _aiService.convertNaturalLanguageRule(description);
      _lastRuleResult = result;
      
      if (!result.isSuccess) {
        _setError(result.error ?? 'Failed to convert rule');
      }
      
      return result;
    } catch (e) {
      final errorResult = AutomationRuleResult.error('Unexpected error: $e');
      _lastRuleResult = errorResult;
      _setError('Unexpected error during rule conversion: $e');
      return errorResult;
    } finally {
      _setProcessing(false);
    }
  }

  /// Explains the effects of an automation rule
  Future<String> explainRuleEffects(String ruleDescription) async {
    if (ruleDescription.trim().isEmpty) {
      return 'Please provide a rule description to explain';
    }

    try {
      _setProcessing(true);
      _clearError();
      
      final explanation = await _aiService.explainRuleEffects(ruleDescription);
      return explanation;
    } catch (e) {
      _setError('Failed to explain rule effects: $e');
      return 'Failed to generate explanation: $e';
    } finally {
      _setProcessing(false);
    }
  }

  /// Creates a Task object from successful intent extraction
  Task? createTaskFromIntent() {
    if (_lastTaskResult?.isSuccess != true) {
      return null;
    }

    final result = _lastTaskResult!;
    return Task.create(
      title: result.title!,
      priority: result.priority!,
      reason: result.reason,
      deadline: result.deadline,
    );
  }

  /// Provides fallback parsing for when AI is not available
  TaskIntentResult fallbackTaskExtraction(String text) {
    try {
      final cleanText = text.trim();
      
      if (cleanText.isEmpty) {
        return TaskIntentResult.error('Please provide a task description');
      }

      // Simple keyword-based priority detection
      TaskPriority priority = TaskPriority.medium;
      if (_containsAny(cleanText.toLowerCase(), ['urgent', 'asap', 'critical', 'high priority', 'important'])) {
        priority = TaskPriority.high;
      } else if (_containsAny(cleanText.toLowerCase(), ['low priority', 'when possible', 'eventually', 'someday'])) {
        priority = TaskPriority.low;
      }

      // Simple deadline detection
      DateTime? deadline;
      final now = DateTime.now();
      if (_containsAny(cleanText.toLowerCase(), ['today'])) {
        deadline = DateTime(now.year, now.month, now.day, 23, 59);
      } else if (_containsAny(cleanText.toLowerCase(), ['tomorrow'])) {
        final tomorrow = now.add(const Duration(days: 1));
        deadline = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
      } else if (_containsAny(cleanText.toLowerCase(), ['next week'])) {
        deadline = now.add(const Duration(days: 7));
      } else if (_containsAny(cleanText.toLowerCase(), ['next month'])) {
        deadline = DateTime(now.year, now.month + 1, now.day);
      }

      // Clean up title
      String title = cleanText;
      
      // Remove common prefixes
      final prefixes = ['create a task to', 'remind me to', 'i need to', 'todo:', 'task:'];
      for (final prefix in prefixes) {
        if (title.toLowerCase().startsWith(prefix)) {
          title = title.substring(prefix.length).trim();
          break;
        }
      }

      // Ensure title is not empty
      if (title.isEmpty) {
        title = 'Complete task';
      }

      // Capitalize first letter
      title = title[0].toUpperCase() + title.substring(1);

      final result = TaskIntentResult.success(
        title: title,
        priority: priority,
        reason: 'Extracted using fallback parsing',
        deadline: deadline,
      );

      _lastTaskResult = result;
      notifyListeners();
      return result;
      
    } catch (e) {
      final errorResult = TaskIntentResult.error('Fallback parsing failed: $e');
      _lastTaskResult = errorResult;
      notifyListeners();
      return errorResult;
    }
  }

  /// Helper method to check if text contains any of the given keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Clears the last error
  void clearError() {
    _clearError();
  }

  /// Clears the last results
  void clearResults() {
    _lastTaskResult = null;
    _lastRuleResult = null;
    notifyListeners();
  }

  /// Gets AI service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'providerInitialized': _isInitialized,
      'isProcessing': _isProcessing,
      'hasLastError': _lastError != null,
      'hasLastTaskResult': _lastTaskResult != null,
      'hasLastRuleResult': _lastRuleResult != null,
      ..._aiService.getStatistics(),
    };
  }

  /// Sets processing state
  void _setProcessing(bool processing) {
    if (_isProcessing != processing) {
      _isProcessing = processing;
      notifyListeners();
    }
  }

  /// Sets error message
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }
}