import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../app_config.dart';
import '../models/task.dart';
import '../models/activity_log.dart';
import 'storage_service.dart';

/// Service for AI-powered intent extraction and natural language processing
class AIService {
  static final AIService _instance = AIService._internal();
  static AIService get instance => _instance;
  AIService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;
  int _requestCount = 0;
  DateTime? _lastRequestTime;
  
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 60;
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);

  bool get isInitialized => _isInitialized;
  bool get hasApiKey => AppConfig.geminiApiKey.isNotEmpty;

  /// Initializes the AI service with Gemini API
  Future<bool> initialize() async {
    try {
      if (!hasApiKey) {
        await _logError('Gemini API key not provided');
        return false;
      }

      _model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more consistent results
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      _isInitialized = true;
      await _logActivity('AI service initialized successfully');
      return true;
      
    } catch (e) {
      await _logError('Failed to initialize AI service: $e');
      return false;
    }
  }

  /// Extracts task intent from natural language text
  Future<TaskIntentResult> extractTaskIntent(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return TaskIntentResult.error('AI service not available');
      }
    }

    if (!_checkRateLimit()) {
      return TaskIntentResult.error('Rate limit exceeded. Please try again later.');
    }

    try {
      final prompt = _buildTaskExtractionPrompt(text);
      final response = await _makeRequest(prompt);
      
      if (response == null) {
        return TaskIntentResult.error('Failed to get AI response');
      }

      final result = _parseTaskIntentResponse(response);
      await _logActivity('Task intent extracted successfully');
      return result;
      
    } catch (e) {
      await _logError('Task intent extraction failed: $e');
      return TaskIntentResult.error('Failed to extract task intent: $e');
    }
  }

  /// Converts natural language to automation rule
  Future<AutomationRuleResult> convertNaturalLanguageRule(String description) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return AutomationRuleResult.error('AI service not available');
      }
    }

    if (!_checkRateLimit()) {
      return AutomationRuleResult.error('Rate limit exceeded. Please try again later.');
    }

    try {
      final prompt = _buildRuleExtractionPrompt(description);
      final response = await _makeRequest(prompt);
      
      if (response == null) {
        return AutomationRuleResult.error('Failed to get AI response');
      }

      final result = _parseAutomationRuleResponse(response);
      await _logActivity('Automation rule converted successfully');
      return result;
      
    } catch (e) {
      await _logError('Automation rule conversion failed: $e');
      return AutomationRuleResult.error('Failed to convert rule: $e');
    }
  }

  /// Explains the effects of an automation rule
  Future<String> explainRuleEffects(String ruleDescription) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return 'AI service not available for rule explanation';
      }
    }

    if (!_checkRateLimit()) {
      return 'Rate limit exceeded. Please try again later.';
    }

    try {
      final prompt = _buildRuleExplanationPrompt(ruleDescription);
      final response = await _makeRequest(prompt);
      
      if (response == null) {
        return 'Failed to generate rule explanation';
      }

      await _logActivity('Rule explanation generated successfully');
      return response.trim();
      
    } catch (e) {
      await _logError('Rule explanation failed: $e');
      return 'Failed to explain rule effects: $e';
    }
  }

  /// Makes a request to the Gemini API with error handling and retries
  Future<String?> _makeRequest(String prompt) async {
    try {
      _updateRateLimit();
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content)
          .timeout(_requestTimeout);
      
      return response.text;
      
    } on TimeoutException {
      await _logError('AI request timed out');
      return null;
    } catch (e) {
      await _logError('AI request failed: $e');
      return null;
    }
  }

  /// Builds prompt for task intent extraction
  String _buildTaskExtractionPrompt(String text) {
    return '''
You are a task management assistant. Extract task information from the following natural language input and return it as JSON.

Input: "$text"

Extract the following information:
- title: A clear, concise task title (required)
- priority: "low", "medium", or "high" (default: "medium")
- reason: Why this task is important (optional)
- deadline: ISO 8601 date string if mentioned (optional)

Rules:
1. The title should be actionable and clear
2. Infer priority from urgency words (urgent=high, soon=medium, etc.)
3. Extract deadline from time expressions (tomorrow, next week, etc.)
4. If no clear task is found, set title to "Clarify task request"

Return only valid JSON in this format:
{
  "title": "string",
  "priority": "low|medium|high",
  "reason": "string or null",
  "deadline": "ISO 8601 string or null"
}
''';
  }

  /// Builds prompt for automation rule extraction
  String _buildRuleExtractionPrompt(String description) {
    return '''
You are an automation rule assistant. Convert the following natural language description into a structured automation rule and return it as JSON.

Input: "$description"

Extract the following information:
- name: A descriptive name for the rule
- trigger: When the rule should activate ("task_created", "deadline_approaching", "priority_changed", etc.)
- conditions: Array of conditions that must be met
- actions: Array of actions to perform
- description: Human-readable description of what the rule does

Return only valid JSON in this format:
{
  "name": "string",
  "trigger": "string",
  "conditions": [
    {
      "type": "priority_equals|has_deadline|title_contains|etc",
      "value": "string"
    }
  ],
  "actions": [
    {
      "type": "send_notification|set_priority|add_tag|etc",
      "parameters": {
        "title": "string",
        "message": "string"
      }
    }
  ],
  "description": "string"
}
''';
  }

  /// Builds prompt for rule explanation
  String _buildRuleExplanationPrompt(String ruleDescription) {
    return '''
You are a helpful assistant. Explain in simple terms what the following automation rule will do:

Rule: "$ruleDescription"

Provide a clear, user-friendly explanation of:
1. When the rule will trigger
2. What conditions must be met
3. What actions will be performed
4. The overall benefit to the user

Keep the explanation concise and easy to understand.
''';
  }

  /// Parses task intent response from AI
  TaskIntentResult _parseTaskIntentResponse(String response) {
    try {
      final cleanResponse = _cleanJsonResponse(response);
      final json = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      final title = json['title'] as String? ?? 'Untitled Task';
      final priorityStr = json['priority'] as String? ?? 'medium';
      final reason = json['reason'] as String?;
      final deadlineStr = json['deadline'] as String?;
      
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
      return TaskIntentResult.error('Failed to parse AI response: $e');
    }
  }

  /// Parses automation rule response from AI
  AutomationRuleResult _parseAutomationRuleResponse(String response) {
    try {
      final cleanResponse = _cleanJsonResponse(response);
      final json = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      return AutomationRuleResult.success(
        name: json['name'] as String? ?? 'Unnamed Rule',
        trigger: json['trigger'] as String? ?? 'task_created',
        conditions: json['conditions'] as List<dynamic>? ?? [],
        actions: json['actions'] as List<dynamic>? ?? [],
        description: json['description'] as String? ?? '',
      );
      
    } catch (e) {
      return AutomationRuleResult.error('Failed to parse automation rule: $e');
    }
  }

  /// Cleans JSON response from AI (removes markdown formatting, etc.)
  String _cleanJsonResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
    
    // Remove any leading/trailing whitespace
    cleaned = cleaned.trim();
    
    // Find the first { and last } to extract just the JSON
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
    
    return cleaned;
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
          'service': 'ai',
          'requestCount': _requestCount,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log AI activity: $e');
      }
    }
  }

  /// Logs an error
  Future<void> _logError(String errorMessage) async {
    try {
      final log = ActivityLog.errorOccurred(
        errorMessage: errorMessage,
        additionalMetadata: {
          'service': 'ai',
          'requestCount': _requestCount,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log AI error: $e');
      }
    }
  }

  /// Gets service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'hasApiKey': hasApiKey,
      'requestCount': _requestCount,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'rateLimitRemaining': _maxRequestsPerMinute - _requestCount,
    };
  }
}

/// Result class for task intent extraction
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

/// Result class for automation rule conversion
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