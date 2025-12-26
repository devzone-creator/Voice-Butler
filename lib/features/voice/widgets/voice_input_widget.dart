import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/voice_service.dart';
import '../providers/voice_provider.dart';
import 'voice_input_button.dart';

/// A comprehensive voice input widget with fallback manual text input
class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTextSubmitted;
  final String? hintText;
  final String? labelText;
  final bool showManualInput;
  final bool autoFocusManualInput;
  final int? maxLines;
  final TextInputType keyboardType;
  final EdgeInsets padding;

  const VoiceInputWidget({
    super.key,
    required this.onTextSubmitted,
    this.hintText,
    this.labelText,
    this.showManualInput = true,
    this.autoFocusManualInput = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    
    // Auto-show manual input if voice is not available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVoiceAvailability();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkVoiceAvailability() async {
    if (!mounted) return;
    
    final voiceProvider = context.read<VoiceProvider>();
    final isAvailable = await voiceProvider.checkAvailability();
    
    if (!isAvailable && widget.showManualInput) {
      setState(() {
        _showManualInput = true;
      });
      
      if (widget.autoFocusManualInput) {
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildVoiceSection(context, voiceProvider),
              if (widget.showManualInput) ...[
                const SizedBox(height: 16),
                _buildManualInputSection(context, voiceProvider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          widget.hintText ?? 'Speak or type your request',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSection(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice Input',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (voiceProvider.state == VoiceInputState.permissionDenied ||
                    voiceProvider.state == VoiceInputState.error) ...[
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showVoiceSettings(context),
                    tooltip: 'Voice settings',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            VoiceInputButton(
              onTextReceived: () {
                final text = voiceProvider.getFinalText();
                if (text.isNotEmpty) {
                  widget.onTextSubmitted(text);
                }
              },
              onTextChanged: (text) {
                // Update manual input field with voice result
                _textController.text = text;
              },
              size: 64,
              showText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSection(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.keyboard,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Manual Input',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showManualInput = !_showManualInput;
                    });
                    if (_showManualInput && widget.autoFocusManualInput) {
                      _focusNode.requestFocus();
                    }
                  },
                  icon: Icon(_showManualInput ? Icons.keyboard_hide : Icons.keyboard),
                  label: Text(_showManualInput ? 'Hide' : 'Show'),
                ),
              ],
            ),
            if (_showManualInput) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Type your request here...',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_textController.text.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            setState(() {});
                          },
                          tooltip: 'Clear text',
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _textController.text.isNotEmpty
                            ? () => _submitManualText()
                            : null,
                        tooltip: 'Submit',
                      ),
                    ],
                  ),
                ),
                onChanged: (text) {
                  setState(() {}); // Update UI for clear button
                },
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    _submitManualText();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitManualText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onTextSubmitted(text);
      _textController.clear();
      setState(() {});
    }
  }

  void _showVoiceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Input Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice input requires microphone permission.'),
            const SizedBox(height: 16),
            const Text('To enable voice input:'),
            const SizedBox(height: 8),
            const Text('1. Go to device Settings'),
            const Text('2. Find this app in Apps/Applications'),
            const Text('3. Enable Microphone permission'),
            const SizedBox(height: 16),
            const Text('You can also use manual text input as an alternative.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}