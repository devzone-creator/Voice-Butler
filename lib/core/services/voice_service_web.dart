import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import 'storage_service.dart';

/// Enum representing voice input states
enum VoiceInputState {
  idle,
  initializing,
  listening,
  processing,
  error,
  permissionDenied,
}

/// Enum representing voice input errors
enum VoiceInputError {
  permissionDenied,
  microphoneNotAvailable,
  speechRecognitionNotAvailable,
  networkError,
  timeout,
  unknown,
}

/// Service for handling voice input and speech-to-text conversion
/// This is a simplified implementation for web compatibility
class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  static VoiceService get instance => _instance;
  VoiceService._internal();

  VoiceInputState _state = VoiceInputState.idle;
  VoiceInputError? _lastError;
  String _lastRecognizedText = '';
  double _confidenceLevel = 0.0;
  bool _isInitialized = false;
  Timer? _timeoutTimer;
  
  // Configuration
  static const Duration _listeningTimeout = Duration(seconds: 30);

  // Getters
  VoiceInputState get state => _state;
  VoiceInputError? get lastError => _lastError;
  String get lastRecognizedText => _lastRecognizedText;
  double get confidenceLevel => _confidenceLevel;
  bool get isInitialized => _isInitialized;
  bool get isListening => _state == VoiceInputState.listening;
  bool get isAvailable => _isInitialized;

  /// Initializes the voice service
  Future<bool> initialize() async {
    try {
      _setState(VoiceInputState.initializing);
      _clearError();

      // For now, simulate initialization
      // In a real implementation, this would check for Web Speech API availability
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (kIsWeb) {
        // On web, we would check for speech recognition support
        // For now, we'll simulate that it's available
        _isInitialized = true;
        _setState(VoiceInputState.idle);
        await _logActivity('Voice service initialized successfully');
        return true;
      } else {
        // On other platforms, mark as not available
        _setError(VoiceInputError.speechRecognitionNotAvailable);
        _setState(VoiceInputState.error);
        await _logError('Voice service not available on this platform');
        return false;
      }
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _setState(VoiceInputState.error);
      await _logError('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Starts listening for voice input
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_state == VoiceInputState.listening) {
      return true;
    }

    try {
      _setState(VoiceInputState.listening);
      _clearError();
      _lastRecognizedText = '';
      _confidenceLevel = 0.0;

      // Set timeout timer
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(_listeningTimeout, () {
        if (_state == VoiceInputState.listening) {
          stopListening();
          _setError(VoiceInputError.timeout);
        }
      });

      await _logActivity('Started voice listening');
      
      // Simulate voice recognition for testing
      if (kDebugMode) {
        // In debug mode, simulate receiving voice input after a short delay
        Timer(const Duration(seconds: 2), () {
          if (_state == VoiceInputState.listening) {
            _lastRecognizedText = 'Create a new task for testing';
            _confidenceLevel = 0.95;
            _setState(VoiceInputState.processing);
            notifyListeners();
            
            // Complete processing after a brief delay
            Timer(const Duration(milliseconds: 500), () {
              _setState(VoiceInputState.idle);
              notifyListeners();
            });
          }
        });
      }
      
      return true;
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _setState(VoiceInputState.error);
      await _logError('Failed to start listening: $e');
      return false;
    }
  }

  /// Stops listening for voice input
  Future<void> stopListening() async {
    try {
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      if (_state == VoiceInputState.listening) {
        _setState(VoiceInputState.processing);
        
        // Brief delay to allow final processing
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      _setState(VoiceInputState.idle);
      await _logActivity('Stopped voice listening');
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _setState(VoiceInputState.error);
      await _logError('Failed to stop listening: $e');
    }
  }

  /// Cancels current listening session
  Future<void> cancelListening() async {
    try {
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      _lastRecognizedText = '';
      _confidenceLevel = 0.0;
      _setState(VoiceInputState.idle);
      
      await _logActivity('Cancelled voice listening');
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _setState(VoiceInputState.error);
      await _logError('Failed to cancel listening: $e');
    }
  }

  /// Gets available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    return [
      'en-US',
      'en-GB',
      'es-ES',
      'fr-FR',
      'de-DE',
      'it-IT',
      'pt-BR',
      'ja-JP',
      'ko-KR',
      'zh-CN',
    ];
  }

  /// Checks if speech recognition is available on the device
  Future<bool> checkAvailability() async {
    return kIsWeb; // For now, assume available on web
  }

  /// Sets the current state and notifies listeners
  void _setState(VoiceInputState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Sets an error and notifies listeners
  void _setError(VoiceInputError error) {
    _lastError = error;
    notifyListeners();
  }

  /// Clears the current error
  void _clearError() {
    _lastError = null;
  }

  /// Gets a human-readable error message
  String getErrorMessage(VoiceInputError error) {
    switch (error) {
      case VoiceInputError.permissionDenied:
        return 'Microphone permission is required for voice input. Please enable it in your browser settings.';
      case VoiceInputError.microphoneNotAvailable:
        return 'Microphone is not available on this device.';
      case VoiceInputError.speechRecognitionNotAvailable:
        return 'Speech recognition is not available in this browser. Please use Chrome or Edge.';
      case VoiceInputError.networkError:
        return 'Network error occurred during speech recognition. Please check your connection.';
      case VoiceInputError.timeout:
        return 'Voice input timed out. Please try again.';
      case VoiceInputError.unknown:
        return 'An unknown error occurred during voice input.';
    }
  }

  /// Gets the current error message if any
  String? get currentErrorMessage {
    return _lastError != null ? getErrorMessage(_lastError!) : null;
  }

  /// Logs an activity
  Future<void> _logActivity(String message) async {
    try {
      final log = ActivityLog.create(
        type: ActivityType.automationApplied,
        description: message,
        metadata: {
          'service': 'voice',
          'state': _state.name,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      // Don't throw errors from logging
      if (kDebugMode) {
        print('Failed to log voice activity: $e');
      }
    }
  }

  /// Logs an error
  Future<void> _logError(String errorMessage) async {
    try {
      final log = ActivityLog.errorOccurred(
        errorMessage: errorMessage,
        additionalMetadata: {
          'service': 'voice',
          'state': _state.name,
        },
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      // Don't throw errors from logging
      if (kDebugMode) {
        print('Failed to log voice error: $e');
      }
    }
  }

  /// Disposes of the service
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Gets service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isAvailable': isAvailable,
      'currentState': _state.name,
      'lastError': _lastError?.name,
      'lastRecognizedText': _lastRecognizedText,
      'confidenceLevel': _confidenceLevel,
      'isListening': isListening,
    };
  }
}

