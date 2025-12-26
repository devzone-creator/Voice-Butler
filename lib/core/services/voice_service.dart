import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';
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
class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  static VoiceService get instance => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  
  VoiceInputState _state = VoiceInputState.idle;
  VoiceInputError? _lastError;
  String _lastRecognizedText = '';
  double _confidenceLevel = 0.0;
  bool _isInitialized = false;
  Timer? _timeoutTimer;
  
  // Configuration
  static const Duration _listeningTimeout = Duration(seconds: 30);
  static const Duration _pauseTimeout = Duration(seconds: 3);
  static const double _minimumConfidence = 0.3;

  // Getters
  VoiceInputState get state => _state;
  VoiceInputError? get lastError => _lastError;
  String get lastRecognizedText => _lastRecognizedText;
  double get confidenceLevel => _confidenceLevel;
  bool get isInitialized => _isInitialized;
  bool get isListening => _state == VoiceInputState.listening;
  bool get isAvailable => _isInitialized && _speechToText.isAvailable;

  /// Initializes the voice service
  Future<bool> initialize() async {
    try {
      _setState(VoiceInputState.initializing);
      _clearError();

      // Check and request microphone permission
      final permissionStatus = await _checkMicrophonePermission();
      if (!permissionStatus) {
        _setError(VoiceInputError.permissionDenied);
        _setState(VoiceInputState.permissionDenied);
        return false;
      }

      // Initialize speech to text
      final isAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: kDebugMode,
      );

      if (!isAvailable) {
        _setError(VoiceInputError.speechRecognitionNotAvailable);
        _setState(VoiceInputState.error);
        await _logError('Speech recognition not available on this device');
        return false;
      }

      _isInitialized = true;
      _setState(VoiceInputState.idle);
      
      await _logActivity('Voice service initialized successfully');
      return true;
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _setState(VoiceInputState.error);
      await _logError('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Checks and requests microphone permission
  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        await _logError('Microphone permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e) {
      await _logError('Error checking microphone permission: $e');
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
      return true; // Already listening
    }

    try {
      _setState(VoiceInputState.listening);
      _clearError();
      _lastRecognizedText = '';
      _confidenceLevel = 0.0;

      // Start listening with configuration
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: _listeningTimeout,
        pauseFor: _pauseTimeout,
        partialResults: true,
        localeId: 'en_US', // Can be made configurable
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
      );

      // Set timeout timer
      _timeoutTimer = Timer(_listeningTimeout, () {
        if (_state == VoiceInputState.listening) {
          stopListening();
          _setError(VoiceInputError.timeout);
        }
      });

      await _logActivity('Started voice listening');
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

      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      _setState(VoiceInputState.processing);
      
      // Brief delay to allow final processing
      await Future.delayed(const Duration(milliseconds: 500));
      
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

      if (_speechToText.isListening) {
        await _speechToText.cancel();
      }

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
  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _speechToText.locales();
    } catch (e) {
      await _logError('Failed to get available locales: $e');
      return [];
    }
  }

  /// Checks if speech recognition is available on the device
  Future<bool> checkAvailability() async {
    try {
      return await SpeechToText().initialize();
    } catch (e) {
      return false;
    }
  }

  /// Handles speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    try {
      _lastRecognizedText = result.recognizedWords;
      _confidenceLevel = result.confidence;
      
      // Only accept results with sufficient confidence
      if (result.hasConfidenceRating && result.confidence < _minimumConfidence) {
        return;
      }

      // Notify listeners of new results
      notifyListeners();
      
      // If this is a final result, stop listening
      if (result.finalResult) {
        _setState(VoiceInputState.processing);
        _logActivity('Voice recognition completed: "${result.recognizedWords}"');
      }
      
    } catch (e) {
      _setError(VoiceInputError.unknown);
      _logError('Error processing speech result: $e');
    }
  }

  /// Handles speech recognition errors
  void _onSpeechError(SpeechRecognitionError error) {
    try {
      VoiceInputError voiceError;
      
      switch (error.errorMsg) {
        case 'error_permission':
          voiceError = VoiceInputError.permissionDenied;
          break;
        case 'error_network':
        case 'error_network_timeout':
          voiceError = VoiceInputError.networkError;
          break;
        case 'error_no_match':
          // This is not really an error, just no speech detected
          _setState(VoiceInputState.idle);
          return;
        case 'error_busy':
        case 'error_client':
        case 'error_server':
        default:
          voiceError = VoiceInputError.unknown;
      }
      
      _setError(voiceError);
      _setState(VoiceInputState.error);
      _logError('Speech recognition error: ${error.errorMsg}');
      
    } catch (e) {
      _logError('Error handling speech error: $e');
    }
  }

  /// Handles speech recognition status changes
  void _onSpeechStatus(String status) {
    try {
      switch (status) {
        case 'listening':
          if (_state != VoiceInputState.listening) {
            _setState(VoiceInputState.listening);
          }
          break;
        case 'notListening':
          if (_state == VoiceInputState.listening) {
            _setState(VoiceInputState.processing);
          }
          break;
        case 'done':
          _setState(VoiceInputState.idle);
          break;
      }
    } catch (e) {
      _logError('Error handling speech status: $e');
    }
  }

  /// Handles sound level changes during listening
  void _onSoundLevelChange(double level) {
    // This can be used for UI feedback (e.g., visualizing sound levels)
    // For now, we just notify listeners
    notifyListeners();
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
        return 'Microphone permission is required for voice input. Please enable it in settings.';
      case VoiceInputError.microphoneNotAvailable:
        return 'Microphone is not available on this device.';
      case VoiceInputError.speechRecognitionNotAvailable:
        return 'Speech recognition is not available on this device.';
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
      print('Failed to log voice activity: $e');
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
      print('Failed to log voice error: $e');
    }
  }

  /// Disposes of the service
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    if (_speechToText.isListening) {
      _speechToText.cancel();
    }
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