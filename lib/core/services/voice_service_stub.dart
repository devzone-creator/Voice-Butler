// Stub implementation - should not be used
// This file exists for conditional imports only

import 'package:flutter/foundation.dart';

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

/// Stub implementation of VoiceService
class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  static VoiceService get instance => _instance;
  VoiceService._internal();

  VoiceInputState get state => VoiceInputState.error;
  VoiceInputError? get lastError => VoiceInputError.speechRecognitionNotAvailable;
  String get lastRecognizedText => '';
  double get confidenceLevel => 0.0;
  bool get isInitialized => false;
  bool get isListening => false;
  bool get isAvailable => false;
  String? get currentErrorMessage => 'Voice service not available on this platform';

  Future<bool> initialize() async => false;
  Future<bool> startListening() async => false;
  Future<void> stopListening() async {}
  Future<void> cancelListening() async {}
  Future<List<String>> getAvailableLocales() async => [];
  Future<bool> checkAvailability() async => false;
  String getErrorMessage(VoiceInputError error) => 'Voice service not available';
  Map<String, dynamic> getStatistics() => {
    'isInitialized': false,
    'isAvailable': false,
    'currentState': 'error',
    'lastError': 'speechRecognitionNotAvailable',
    'lastRecognizedText': '',
    'confidenceLevel': 0.0,
    'isListening': false,
  };
}

