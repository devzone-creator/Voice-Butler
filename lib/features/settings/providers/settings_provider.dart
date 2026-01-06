import 'package:flutter/foundation.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_ai_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  
  // Advanced Mode settings
  bool _isAdvancedMode = false;
  
  // Notification settings
  bool _notificationsEnabled = true;
  bool _backgroundProcessingEnabled = true;
  int _defaultReminderDelayMinutes = 60;
  
  // Storage settings
  int _maxLogsToKeep = 5000;
  int _maxLogRetentionDays = 30;
  
  // AI Configuration
  String? _geminiApiKey;
  
  // Cache for statistics
  int _activityLogCount = 0;
  int _customRulesCount = 0;
  
  // Getters
  bool get isAdvancedMode => _isAdvancedMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get backgroundProcessingEnabled => _backgroundProcessingEnabled;
  int get defaultReminderDelayMinutes => _defaultReminderDelayMinutes;
  int get maxLogsToKeep => _maxLogsToKeep;
  int get maxLogRetentionDays => _maxLogRetentionDays;
  int get activityLogCount => _activityLogCount;
  int get customRulesCount => _customRulesCount;
  String? get geminiApiKey => _geminiApiKey;
  bool get hasGeminiApiKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
  
  double get storageUsagePercentage {
    if (_maxLogsToKeep == 0) return 0.0;
    return (_activityLogCount / _maxLogsToKeep) * 100;
  }

  SettingsProvider() {
    _loadSettings();
  }

  /// Loads settings from storage
  Future<void> _loadSettings() async {
    try {
      // Load Advanced Mode setting
      _isAdvancedMode = _storageService.getSetting<bool>('advanced_mode', defaultValue: false) ?? false;
      
      // Load notification settings
      _notificationsEnabled = _storageService.getSetting<bool>('notifications_enabled', defaultValue: true) ?? true;
      _backgroundProcessingEnabled = _storageService.getSetting<bool>('background_processing_enabled', defaultValue: true) ?? true;
      _defaultReminderDelayMinutes = _storageService.getSetting<int>('default_reminder_delay_minutes', defaultValue: 60) ?? 60;
      
      // Load storage settings
      _maxLogsToKeep = _storageService.getSetting<int>('max_logs_to_keep', defaultValue: 5000) ?? 5000;
      _maxLogRetentionDays = _storageService.getSetting<int>('max_log_retention_days', defaultValue: 30) ?? 30;
      
      // Load AI configuration
      _geminiApiKey = _storageService.getSetting<String>('gemini_api_key');
      
      // Load statistics
      await _updateStatistics();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load settings: $e');
      }
    }
  }

  /// Updates cached statistics
  Future<void> _updateStatistics() async {
    try {
      _activityLogCount = _storageService.getAllActivityLogs().length;
      _customRulesCount = _storageService.getAllAutomationRules()
          .where((rule) => !rule.isPreset)
          .length;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update statistics: $e');
      }
    }
  }

  /// Sets Advanced Mode with smooth transition
  Future<void> setAdvancedMode(bool enabled) async {
    try {
      final previousMode = _isAdvancedMode;
      _isAdvancedMode = enabled;
      
      // Save to storage
      await _storageService.setSetting('advanced_mode', enabled);
      
      // Update statistics when enabling advanced mode
      if (enabled && !previousMode) {
        await _updateStatistics();
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print('Advanced Mode ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      // Revert on error
      _isAdvancedMode = !enabled;
      notifyListeners();
      
      if (kDebugMode) {
        print('Failed to set Advanced Mode: $e');
      }
      rethrow;
    }
  }

  /// Sets notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      _notificationsEnabled = enabled;
      await _storageService.setSetting('notifications_enabled', enabled);
      notifyListeners();
    } catch (e) {
      _notificationsEnabled = !enabled;
      notifyListeners();
      if (kDebugMode) {
        print('Failed to set notifications enabled: $e');
      }
    }
  }

  /// Sets background processing enabled
  Future<void> setBackgroundProcessingEnabled(bool enabled) async {
    try {
      _backgroundProcessingEnabled = enabled;
      await _storageService.setSetting('background_processing_enabled', enabled);
      notifyListeners();
    } catch (e) {
      _backgroundProcessingEnabled = !enabled;
      notifyListeners();
      if (kDebugMode) {
        print('Failed to set background processing enabled: $e');
      }
    }
  }

  /// Sets default reminder delay in minutes
  Future<void> setDefaultReminderDelayMinutes(int minutes) async {
    try {
      if (minutes < 1 || minutes > 1440) {
        throw ArgumentError('Reminder delay must be between 1 and 1440 minutes');
      }
      
      _defaultReminderDelayMinutes = minutes;
      await _storageService.setSetting('default_reminder_delay_minutes', minutes);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set default reminder delay: $e');
      }
      rethrow;
    }
  }

  /// Sets maximum logs to keep
  Future<void> setMaxLogsToKeep(int maxLogs) async {
    try {
      if (maxLogs < 100 || maxLogs > 50000) {
        throw ArgumentError('Max logs must be between 100 and 50000');
      }
      
      _maxLogsToKeep = maxLogs;
      await _storageService.setSetting('max_logs_to_keep', maxLogs);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set max logs to keep: $e');
      }
      rethrow;
    }
  }

  /// Sets maximum log retention days
  Future<void> setMaxLogRetentionDays(int days) async {
    try {
      if (days < 7 || days > 365) {
        throw ArgumentError('Log retention days must be between 7 and 365');
      }
      
      _maxLogRetentionDays = days;
      await _storageService.setSetting('max_log_retention_days', days);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set max log retention days: $e');
      }
      rethrow;
    }
  }

  /// Performs manual cleanup and updates statistics
  Future<void> performManualCleanup() async {
    try {
      final result = await _storageService.performActivityLogMaintenance(
        maxLogsToKeep: _maxLogsToKeep,
        notifyUser: false, // Don't create notification logs during manual cleanup
      );
      
      await _updateStatistics();
      notifyListeners();
      
      if (kDebugMode) {
        print('Manual cleanup completed: ${result['message']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to perform manual cleanup: $e');
      }
      rethrow;
    }
  }

  /// Sets Gemini API key
  Future<void> setGeminiApiKey(String? apiKey) async {
    try {
      _geminiApiKey = apiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        await _storageService.setSetting('gemini_api_key', apiKey);
      } else {
        await _storageService.deleteSetting('gemini_api_key');
        _geminiApiKey = null;
      }
      notifyListeners();
      
      // Reinitialize AI service with new key
      try {
        await BackendAIService.instance.initialize();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to reinitialize AI service: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set Gemini API key: $e');
      }
      rethrow;
    }
  }

  /// Refreshes all statistics
  Future<void> refreshStatistics() async {
    await _updateStatistics();
    notifyListeners();
  }

  /// Gets Advanced Mode features availability
  Map<String, bool> getAdvancedModeFeatures() {
    return {
      'customRules': _isAdvancedMode,
      'presetWorkflows': _isAdvancedMode,
      'ruleBuilder': _isAdvancedMode,
      'advancedAutomation': _isAdvancedMode,
      'naturalLanguageRules': _isAdvancedMode,
    };
  }

  /// Checks if a specific advanced feature is available
  bool isAdvancedFeatureAvailable(String featureName) {
    final features = getAdvancedModeFeatures();
    return features[featureName] ?? false;
  }

  /// Gets settings summary for debugging
  Map<String, dynamic> getSettingsSummary() {
    return {
      'advancedMode': _isAdvancedMode,
      'notificationsEnabled': _notificationsEnabled,
      'backgroundProcessingEnabled': _backgroundProcessingEnabled,
      'defaultReminderDelayMinutes': _defaultReminderDelayMinutes,
      'maxLogsToKeep': _maxLogsToKeep,
      'maxLogRetentionDays': _maxLogRetentionDays,
      'activityLogCount': _activityLogCount,
      'customRulesCount': _customRulesCount,
      'storageUsagePercentage': storageUsagePercentage,
    };
  }

  /// Resets all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      _isAdvancedMode = false;
      _notificationsEnabled = true;
      _backgroundProcessingEnabled = true;
      _defaultReminderDelayMinutes = 60;
      _maxLogsToKeep = 5000;
      _maxLogRetentionDays = 30;
      
      // Save all defaults
      await _storageService.setSetting('advanced_mode', false);
      await _storageService.setSetting('notifications_enabled', true);
      await _storageService.setSetting('background_processing_enabled', true);
      await _storageService.setSetting('default_reminder_delay_minutes', 60);
      await _storageService.setSetting('max_logs_to_keep', 5000);
      await _storageService.setSetting('max_log_retention_days', 30);
      
      await _updateStatistics();
      notifyListeners();
      
      if (kDebugMode) {
        print('Settings reset to defaults');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to reset settings: $e');
      }
      rethrow;
    }
  }
}