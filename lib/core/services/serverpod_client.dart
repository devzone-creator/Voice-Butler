import '../app_config.dart';

/// Mock Serverpod client service for backend communication
/// TODO: Replace with actual Serverpod client when server is ready
class ServerpodClientService {
  static final ServerpodClientService _instance = ServerpodClientService._internal();
  static ServerpodClientService get instance => _instance;
  ServerpodClientService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  
  MockClient get client {
    if (!_isInitialized) {
      throw Exception('Serverpod client not initialized');
    }
    return MockClient();
  }

  /// Initialize Serverpod client (mock)
  Future<bool> initialize() async {
    try {
      // Mock initialization - always succeeds for now
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Close client connection (mock)
  Future<void> close() async {
    _isInitialized = false;
  }
}

/// Mock client for development
class MockClient {
  Future<Map<String, dynamic>> callEndpoint(
    String service,
    String method,
    Map<String, dynamic> parameters,
  ) async {
    // Mock response for AI endpoints
    if (service == 'ai' && method == 'extractTaskIntent') {
      return {
        'success': true,
        'data': {
          'title': 'Complete task: ${parameters['text']}',
          'priority': 'medium',
          'reason': 'Mock AI processing',
          'deadline': null,
        },
      };
    }
    
    if (service == 'ai' && method == 'convertNaturalLanguageRule') {
      return {
        'success': true,
        'data': {
          'name': 'Custom Rule',
          'trigger': 'task_created',
          'conditions': <dynamic>[],
          'actions': <dynamic>[],
          'description': 'Mock rule from: ${parameters['description']}',
        },
      };
    }
    
    if (service == 'ai' && method == 'explainRuleEffects') {
      return {
        'success': true,
        'explanation': 'This rule will: ${parameters['ruleDescription']} (mock explanation)',
      };
    }
    
    return {'success': false, 'error': 'Unknown endpoint'};
  }
  
  Future<void> close() async {
    // Mock close
  }
}