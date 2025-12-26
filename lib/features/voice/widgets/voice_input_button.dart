import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/voice_service.dart';
import '../providers/voice_provider.dart';

/// A voice input button widget with visual feedback and state management
class VoiceInputButton extends StatefulWidget {
  final VoidCallback? onTextReceived;
  final Function(String)? onTextChanged;
  final String? tooltip;
  final double size;
  final bool showText;
  final EdgeInsets padding;

  const VoiceInputButton({
    super.key,
    this.onTextReceived,
    this.onTextChanged,
    this.tooltip,
    this.size = 56.0,
    this.showText = true,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation on repeat
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        return Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVoiceButton(context, voiceProvider),
              if (widget.showText) ...[
                const SizedBox(height: 8),
                _buildStatusText(context, voiceProvider),
                if (voiceProvider.currentText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildRecognizedText(context, voiceProvider),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceButton(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine button state and colors
    Color buttonColor;
    Color iconColor;
    IconData iconData;
    bool isEnabled = true;

    switch (voiceProvider.state) {
      case VoiceInputState.idle:
        buttonColor = colorScheme.primary;
        iconColor = colorScheme.onPrimary;
        iconData = Icons.mic;
        break;
      case VoiceInputState.initializing:
        buttonColor = colorScheme.secondary;
        iconColor = colorScheme.onSecondary;
        iconData = Icons.hourglass_empty;
        isEnabled = false;
        break;
      case VoiceInputState.listening:
        buttonColor = colorScheme.error;
        iconColor = colorScheme.onError;
        iconData = Icons.mic;
        break;
      case VoiceInputState.processing:
        buttonColor = colorScheme.tertiary;
        iconColor = colorScheme.onTertiary;
        iconData = Icons.hourglass_bottom;
        isEnabled = false;
        break;
      case VoiceInputState.error:
        buttonColor = colorScheme.error.withValues(alpha: 0.7);
        iconColor = colorScheme.onError;
        iconData = Icons.mic_off;
        break;
      case VoiceInputState.permissionDenied:
        buttonColor = colorScheme.outline;
        iconColor = colorScheme.onSurface;
        iconData = Icons.mic_off;
        break;
    }

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _scaleController.forward() : null,
      onTapUp: isEnabled ? (_) => _scaleController.reverse() : null,
      onTapCancel: isEnabled ? () => _scaleController.reverse() : null,
      child: Tooltip(
        message: widget.tooltip ?? _getTooltipMessage(voiceProvider.state),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
          builder: (context, child) {
            final scale = _scaleAnimation.value;
            final pulse = voiceProvider.isListening ? _pulseAnimation.value : 1.0;
            
            return Transform.scale(
              scale: scale * pulse,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: voiceProvider.isListening ? 12 : 6,
                      spreadRadius: voiceProvider.isListening ? 2 : 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    onTap: isEnabled ? () => _handleButtonPress(voiceProvider) : null,
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: widget.size * 0.4,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    String statusText;
    Color textColor;

    switch (voiceProvider.state) {
      case VoiceInputState.idle:
        statusText = 'Tap to speak';
        textColor = theme.colorScheme.onSurface;
        break;
      case VoiceInputState.initializing:
        statusText = 'Initializing...';
        textColor = theme.colorScheme.secondary;
        break;
      case VoiceInputState.listening:
        statusText = 'Listening... Tap to stop';
        textColor = theme.colorScheme.error;
        break;
      case VoiceInputState.processing:
        statusText = 'Processing...';
        textColor = theme.colorScheme.tertiary;
        break;
      case VoiceInputState.error:
        statusText = voiceProvider.currentErrorMessage ?? 'Error occurred';
        textColor = theme.colorScheme.error;
        break;
      case VoiceInputState.permissionDenied:
        statusText = 'Microphone permission required';
        textColor = theme.colorScheme.outline;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        statusText,
        key: ValueKey(statusText),
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRecognizedText(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recognized:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            voiceProvider.currentText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (voiceProvider.confidenceLevel > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Confidence: ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: voiceProvider.confidenceLevel,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getConfidenceColor(theme.colorScheme, voiceProvider.confidenceLevel),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(voiceProvider.confidenceLevel * 100).toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTooltipMessage(VoiceInputState state) {
    switch (state) {
      case VoiceInputState.idle:
        return 'Start voice input';
      case VoiceInputState.initializing:
        return 'Initializing voice recognition';
      case VoiceInputState.listening:
        return 'Stop voice input';
      case VoiceInputState.processing:
        return 'Processing speech';
      case VoiceInputState.error:
        return 'Voice input error - tap to retry';
      case VoiceInputState.permissionDenied:
        return 'Microphone permission required';
    }
  }

  Color _getConfidenceColor(ColorScheme colorScheme, double confidence) {
    if (confidence >= 0.8) {
      return colorScheme.primary;
    } else if (confidence >= 0.5) {
      return colorScheme.secondary;
    } else {
      return colorScheme.error;
    }
  }

  Future<void> _handleButtonPress(VoiceProvider voiceProvider) async {
    try {
      switch (voiceProvider.state) {
        case VoiceInputState.idle:
        case VoiceInputState.error:
        case VoiceInputState.permissionDenied:
          // Start listening
          final success = await voiceProvider.startVoiceInput();
          if (!success && mounted) {
            _showErrorSnackBar(context, voiceProvider.getErrorMessage());
          }
          break;
          
        case VoiceInputState.listening:
          // Stop listening and get result
          await voiceProvider.stopVoiceInput();
          final text = voiceProvider.getFinalText();
          if (text.isNotEmpty) {
            widget.onTextReceived?.call();
            widget.onTextChanged?.call(text);
          }
          break;
          
        case VoiceInputState.initializing:
        case VoiceInputState.processing:
          // Do nothing - button is disabled
          break;
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Voice input failed: $e');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String? message) {
    if (message == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}