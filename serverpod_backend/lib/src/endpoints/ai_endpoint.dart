import 'package:serverpod/serverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// AI endpoint for intent extraction and automation rule processing
class AIEndpoint extends Endpoint {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiModel = 'gemini-2.0-flash';
  
  GenerativeModel? _model;
  
  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: _geminiModel,
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
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
    return _model!;
  }

  /// Extracts task intent from natural language text
  Future<Map<String, dynamic>> extractTaskIntent(Session session, String text) async {
    try {
      if (_geminiApiKey.isEmpty) {
        return {
          'success': false,
          'error': 'Gemini API key not configured on server',
        };
      }

      final prompt = _buildTaskExtractionPrompt(text);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text == null) {
        return {
          'success': false,
          'error': 'No response from Gemini API',
        };
      }

      final parsedData = _parseTaskIntentResponse(response.text!);
      
      return {
        'success': true,
        'data': parsedData,
      };
      
    } catch (e) {
      session.log('Task intent extraction failed: $e');
      return {
        'success': false,
        'error': 'Failed to extract task intent: $e',
      };
    }
  }

  /// Converts natural language to automation rule
  Future<Map<String, dynamic>> convertNaturalLanguageRule(Session session, String description) async {
    try {
      if (_geminiApiKey.isEmpty) {
        return {
          'success': false,
          'error': 'Gemini API key not configured on server',
        };
      }

      final prompt = _buildRuleExtractionPrompt(description);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text == null) {
        return {
          'success': false,
          'error': 'No response from Gemini API',
        };
      }

      final parsedData = _parseAutomationRuleResponse(response.text!);
      
      return {
        'success': true,
        'data': parsedData,
      };
      
    } catch (e) {
      session.log('Automation rule conversion failed: $e');
      return {
        'success': false,
        'error': 'Failed to convert rule: $e',
      };
    }
  }

  /// Explains the effects of an automation rule
  Future<Map<String, dynamic>> explainRuleEffects(Session session, String ruleDescription) async {
    try {
      if (_geminiApiKey.isEmpty) {
        return {
          'success': false,
          'error': 'Gemini API key not configured on server',
        };
      }

      final prompt = _buildRuleExplanationPrompt(ruleDescription);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text == null) {
        return {
          'success': false,
          'error': 'No response from Gemini API',
        };
      }

      return {
        'success': true,
        'explanation': response.text!.trim(),
      };
      
    } catch (e) {
      session.log('Rule explanation failed: $e');
      return {
        'success': false,
        'error': 'Failed to explain rule effects: $e',
      };
    }
  }

  /// Builds prompt for task intent extraction
  String _buildTaskExtractionPrompt(String text) {
    return '''
You are an AI task refinement engine for a voice-based productivity assistant called Voice Butler.Your responsibility is to transform raw user speech into a structured task.Rules:- Rephrase the task into a clear, concise action-oriented title- Infer task priority: LOW, MEDIUM, or HIGH- Provide a brief reason (max 20 words) explaining the priority- Do NOT include any explanations- Do NOT include markdown- Do NOT include natural language outside JSON- Output MUST be valid JSONReturn JSON in this exact schema:{"refinedTitle": "string","priority": "LOW | MEDIUM | HIGH","reason": "string"}Raw Task Input:"$text"Optional Priority Hint:""''';
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

  /// Parses task intent response from Gemini
  Map<String, dynamic> _parseTaskIntentResponse(String response) {
    try {
      final cleanResponse = _cleanJsonResponse(response);
      final json = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      // Map the refined response format to expected format
      final priority = (json['priority'] as String? ?? 'MEDIUM').toLowerCase();
      
      return {
        'title': json['refinedTitle'] as String? ?? 'Untitled Task',
        'priority': priority,
        'reason': json['reason'] as String?,
        'deadline': null, // Deadline extraction can be added later if needed
      };
      
    } catch (e) {
      // Fallback parsing if JSON fails
      return {
        'title': 'Parse task from: ${response.substring(0, response.length > 50 ? 50 : response.length)}...',
        'priority': 'medium',
        'reason': 'AI parsing failed, manual review needed',
        'deadline': null,
      };
    }
  }

  /// Parses automation rule response from Gemini
  Map<String, dynamic> _parseAutomationRuleResponse(String response) {
    try {
      final cleanResponse = _cleanJsonResponse(response);
      final json = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      return {
        'name': json['name'] as String? ?? 'Unnamed Rule',
        'trigger': json['trigger'] as String? ?? 'task_created',
        'conditions': json['conditions'] as List<dynamic>? ?? [],
        'actions': json['actions'] as List<dynamic>? ?? [],
        'description': json['description'] as String? ?? '',
      };
      
    } catch (e) {
      // Fallback rule if JSON fails
      return {
        'name': 'Custom Rule',
        'trigger': 'task_created',
        'conditions': [],
        'actions': [
          {
            'type': 'send_notification',
            'parameters': {
              'title': 'Rule Created',
              'message': 'AI parsing failed, please review rule manually',
            }
          }
        ],
        'description': 'Rule created from: ${response.substring(0, response.length > 100 ? 100 : response.length)}...',
      };
    }
  }

  /// Cleans JSON response from Gemini
  String _cleanJsonResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
    
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
}