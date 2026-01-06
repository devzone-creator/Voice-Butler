import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/activity_log.dart';
import 'serverpod_client.dart';
import 'storage_service.dart';

/// Service for AI-powered intent extraction via Serverpod backend
class BackendAIService {
  static final BackendAIService _instance = BackendAIService._internal();
  static BackendAIService get instance => _instance;
  BackendAIService._internal();

  bool _isInitialized = false;
  int _requestCount = 0;
  DateTime? _lastRequestTime;
  
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 60;
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);

  bool get isInitialized => _isInitialized;

  /// Initializes the backend AI service
  Future<bool> initialize() async {
    try {
      final serverpodInitialized = await ServerpodClientService.instance.initialize();
      if (!serverpodInitialized) {
        await _logError('Serverpod client initialization failed');
        return false;
      }

      _isInitialized = true;
      await _logActivity('Backend AI service initialized successfully');
      return true;
      
    } catch (e) {
      await _logError('Failed to initialize backend AI service: $e');
      return false;
    }
  }

  /// Extracts task intent from natural language text via backend
  Future<TaskIntentResult> extractTaskIntent(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return TaskIntentResult.error('Backend AI service not available');
      }
    }

    if (!_checkRateLimit()) {
      return TaskIntentResult.error('Rate limit exceeded. Please try again later.');
    }

    try {
      _updateRateLimit();
      
      // Call Serverpod endpoint for intent extraction
      final client = ServerpodClientService.instance.client;
      final response = await client.callEndpoint(
        'ai',
        'extractTaskIntent',
        {'text': text},
      ).timeout(_requestTimeout);
      
      if (response == null) {
        return TaskIntentResult.error('Failed to get backend response');
      }

      final result = _parseTaskIntentResponse(response);
      await _logActivity('Task intent extracted successfully via backend');
      return result;
      
    } catch (e) {
      await _logError('Backend task intent extraction failed: $e');
      return TaskIntentResult.error('Failed to extract task intent: $e');
    }
  }

  /// Converts natural language to automation rule via backend
  Future<AutomationRuleResult> convertNaturalLanguageRule(String description) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return AutomationRuleResult.error('Backend AI service not available');
      }
    }

    if (!_checkRateLimit()) {
      return AutomationRuleResult.error('Rate limit exceeded. Please try again later.');
    }

    try {
      _updateRateLimit();
      
      // Call Serverpod endpoint for rule conversion
      final client = ServerpodClientService.instance.client;
      final response = await client.callEndpoint(
        'ai',
        'convertNaturalLanguageRule',
        {'description': description},
      ).timeout(_requestTimeout);
      
      if (response == null) {
        return AutomationRuleResult.error('Failed to get backend response');
      }

      final result = _parseAutomationRuleResponse(response);
      await _logActivity('Automation rule converted successfully via backend');
      return result;
      
    } catch (e) {
      await _logError('Backend automation rule conversion failed: $e');
      return AutomationRuleResult.error('Failed to convert rule: $e');
    }
  }

  /// Explains the effects of an automation rule via backend
  Future<String> explainRuleEffects(String ruleDescription) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return 'Backend AI service not available for rule explanation';
      }
    }

    if (!_checkRateLimit()) {
      return 'Rate limit exceeded. Please try again later.';
    }

    try {
      _updateRateLimit();
      
      // Call Serverpod endpoint for rule explanation
      final client = ServerpodClientService.instance.client;
      final response = await client.callEndpoint(
        'ai',
        'explainRuleEffects',
        {'ruleDescription': ruleDescription},
      ).timeout(_requestTimeout);
      
      if (response == null) {
        return 'Failed to generate rule explanation';
      }

      await _logActivity('Rule explanation generated successfully via backend');
      return response['explanation'] as String? ?? 'No explanation available';
      
    } catch (e) {
      await _logError('Backend rule explanation failed: $e');
      return 'Failed to explain rule effects: $e';
    }
  }

  /// Parses task intent response from backend
  TaskIntentResult _parseTaskIntentResponse(Map<String, dynamic> response) {
    try {
      if (response['success'] != true) {
        return TaskIntentResult.error(response['error'] as String? ?? 'Backend processing failed');
      }
      
      final data = response['data'] as Map<String, dynamic>;
      final title = data['title'] as String? ?? 'Untitled Task';
      final priorityStr = data['priority'] as String? ?? 'medium';
      final reason = data['reason'] as String?;
      final deadlineStr = data['deadline'] as String?;
      
      // Parse priority
      TaskPriority priority;
      switch (priorityStr.toLowerCase()) {
        case 'high':
          priority = TaskPriority.high;
          break;
        case 'low':
          priority = TaskPriority.low;
          break;
        default:
          priority = TaskPriority.medium;
      }
      
      // Parse deadline
      DateTime? deadline;
      if (deadlineStr != null && deadlineStr.isNotEmpty) {
        try {
          deadline = DateTime.parse(deadlineStr);
        } catch (e) {
          // Invalid date format, ignore
        }
      }
      
      return TaskIntentResult.success(
        title: title,
        priority: priority,
        reason: reason,
        deadline: deadline,
      );
      
    } catch (e) {
      return TaskIntentResult.error('Failed to parse backend response: $e');
    }
  }

  /// Parses automation rule response from backend
  AutomationRuleResult _parseAutomationRuleResponse(Map<String, dynamic> response) {
    try {
      if (response['success'] != true) {
        return AutomationRuleResult.error(response['error'] as String? ?? 'Backend processing failed');
      }
      
      final data = response['data'] as Map<String, dynamic>;
      
      return AutomationRuleResult.success(
        name: data['name'] as String? ?? 'Unnamed Rule',
        trigger: data['trigger'] as String? ?? 'task_created',
        conditions: data['conditions'] as List<dynamic>? ?? [],
        actions: data['actions'] as List<dynamic>? ?? [],
        description: data['description'] as String? ?? '',
      );
      
    } catch (e) {
      return AutomationRuleResult.error('Failed to parse automation rule: $e');
    }
  }

  /// Checks if request is within rate limits
  bool _checkRateLimit() {
    final now = DateTime.now();
    
    if (_lastRequestTime == null || 
        now.difference(_lastRequestTime!) > _rateLimitWindow) {
      _requestCount = 0;
      _lastRequestTime = now;
    }
    
    return _requestCount < _maxRequestsPerMinute;
  }

  /// Updates rate limit counters
  void _updateRateLimit() {
    _requestCount++;
    _lastRequestTime = DateTime.now();
  }

  /// Logs an activity
  Future<void> _logActivity(String message) async {
    try {
      final log = ActivityLog.create(
        type: ActivityType.automationApplied,
        description: message,
        metadata: {
          'service': 'backend_ai',
          'requestCount': _requestCount,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log backend AI activity: $e');
      }
    }
  }

  /// Logs an error
  Future<void> _logError(String errorMessage) async {
    try {
      final log = ActivityLog.errorOccurred(
        errorMessage: errorMessage,
        additionalMetadata: {
          'service': 'backend_ai',
          'requestCount': _requestCount,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log backend AI error: $e');
      }
    }
  }

  /// Gets service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'serverpodInitialized': ServerpodClientService.instance.isInitialized,
      'requestCount': _requestCount,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'rateLimitRemaining': _maxRequestsPerMinute - _requestCount,
    };
  }
}

/// Result class for task intent extraction (reused from ai_service.dart)
class TaskIntentResult {
  final bool isSuccess;
  final String? error;
  final String? title;
  final TaskPriority? priority;
  final String? reason;
  final DateTime? deadline;

  TaskIntentResult._({
    required this.isSuccess,
    this.error,
    this.title,
    this.priority,
    this.reason,
    this.deadline,
  });

  factory TaskIntentResult.success({
    required String title,
    required TaskPriority priority,
    String? reason,
    DateTime? deadline,
  }) {
    return TaskIntentResult._(
      isSuccess: true,
      title: title,
      priority: priority,
      reason: reason,
      deadline: deadline,
    );
  }

  factory TaskIntentResult.error(String error) {
    return TaskIntentResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Result class for automation rule conversion (reused from ai_service.dart)
class AutomationRuleResult {
  final bool isSuccess;
  final String? error;
  final String? name;
  final String? trigger;
  final List<dynamic>? conditions;
  final List<dynamic>? actions;
  final String? description;

  AutomationRuleResult._({
    required this.isSuccess,
    this.error,
    this.name,
    this.trigger,
    this.conditions,
    this.actions,
    this.description,
  });

  factory AutomationRuleResult.success({
    required String name,
    required String trigger,
    required List<dynamic> conditions,
    required List<dynamic> actions,
    required String description,
  }) {
    return AutomationRuleResult._(
      isSuccess: true,
      name: name,
      trigger: trigger,
      conditions: conditions,
      actions: actions,
      description: description,
    );
  }

  factory AutomationRuleResult.error(String error) {
    return AutomationRuleResult._(
      isSuccess: false,
      error: error,
    );
  }
}