import 'package:flutter/foundation.dart';
import '../../../core/services/voice_service.dart';

/// Provider for managing voice input state and operations
class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService.instance;
  
  bool _isInitialized = false;
  String _currentText = '';
  bool _isProcessing = false;

  // Getters
  bool get isInitialized => _isInitialized;
  VoiceInputState get state => _voiceService.state;
  VoiceInputError? get lastError => _voiceService.lastError;
  String get lastRecognizedText => _voiceService.lastRecognizedText;
  String get currentText => _currentText;
  double get confidenceLevel => _voiceService.confidenceLevel;
  bool get isListening => _voiceService.isListening;
  bool get isAvailable => _voiceService.isAvailable;
  bool get isProcessing => _isProcessing;
  String? get currentErrorMessage => _voiceService.currentErrorMessage;

  VoiceProvider() {
    // Listen to voice service changes
    _voiceService.addListener(_onVoiceServiceChanged);
  }

  /// Initializes the voice provider
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _setProcessing(true);
      final success = await _voiceService.initialize();
      _isInitialized = success;
      return success;
    } finally {
      _setProcessing(false);
    }
  }

  /// Starts voice input
  Future<bool> startVoiceInput() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      _setProcessing(true);
      _currentText = '';
      final success = await _voiceService.startListening();
      return success;
    } finally {
      _setProcessing(false);
    }
  }

  /// Stops voice input
  Future<void> stopVoiceInput() async {
    try {
      _setProcessing(true);
      await _voiceService.stopListening();
    } finally {
      _setProcessing(false);
    }
  }

  /// Cancels voice input
  Future<void> cancelVoiceInput() async {
    try {
      _setProcessing(true);
      await _voiceService.cancelListening();
      _currentText = '';
    } finally {
      _setProcessing(false);
    }
  }

  /// Gets the final recognized text and clears it
  String getFinalText() {
    final text = _currentText.isNotEmpty ? _currentText : _voiceService.lastRecognizedText;
    _currentText = '';
    return text;
  }

  /// Checks if voice input is available on the device
  Future<bool> checkAvailability() async {
    return await _voiceService.checkAvailability();
  }

  /// Gets available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    return await _voiceService.getAvailableLocales();
  }

  /// Gets a human-readable error message for the current error
  String? getErrorMessage() {
    return _voiceService.currentErrorMessage;
  }

  /// Handles voice service state changes
  void _onVoiceServiceChanged() {
    // Update current text with the latest recognized text
    if (_voiceService.lastRecognizedText.isNotEmpty) {
      _currentText = _voiceService.lastRecognizedText;
    }
    
    // Notify listeners of state changes
    notifyListeners();
  }

  /// Sets processing state
  void _setProcessing(bool processing) {
    if (_isProcessing != processing) {
      _isProcessing = processing;
      notifyListeners();
    }
  }

  /// Gets voice input statistics
  Map<String, dynamic> getStatistics() {
    return {
      'providerInitialized': _isInitialized,
      'currentText': _currentText,
      'isProcessing': _isProcessing,
      ..._voiceService.getStatistics(),
    };
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }
}