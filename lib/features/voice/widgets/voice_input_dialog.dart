import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import 'voice_input_button.dart';

/// A dialog for quick voice input with fallback manual input
class VoiceInputDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? hintText;
  final Function(String) onTextSubmitted;
  final VoidCallback? onCancel;

  const VoiceInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.hintText,
    required this.onTextSubmitted,
    this.onCancel,
  });

  /// Shows a voice input dialog
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? hintText,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => VoiceProvider(),
        child: VoiceInputDialog(
          title: title,
          subtitle: subtitle,
          hintText: hintText,
          onTextSubmitted: (text) => Navigator.of(context).pop(text),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  late TextEditingController _textController;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    
    // Check voice availability and show manual input if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVoiceAvailability();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkVoiceAvailability() async {
    if (!mounted) return;
    
    final voiceProvider = context.read<VoiceProvider>();
    final isAvailable = await voiceProvider.checkAvailability();
    
    if (!isAvailable) {
      setState(() {
        _showManualInput = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        return AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.subtitle != null) ...[
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Voice input section
                _buildVoiceSection(context, voiceProvider),
                
                // Manual input toggle
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showManualInput = !_showManualInput;
                        });
                      },
                      icon: Icon(_showManualInput ? Icons.keyboard_hide : Icons.keyboard),
                      label: Text(_showManualInput ? 'Hide keyboard' : 'Use keyboard'),
                    ),
                  ],
                ),
                
                // Manual input section
                if (_showManualInput) ...[
                  const SizedBox(height: 16),
                  _buildManualInputSection(context),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (_showManualInput && _textController.text.isNotEmpty) ...[
              FilledButton(
                onPressed: () => _submitText(_textController.text),
                child: const Text('Submit'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildVoiceSection(BuildContext context, VoiceProvider voiceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: VoiceInputButton(
        onTextReceived: () {
          final text = voiceProvider.getFinalText();
          if (text.isNotEmpty) {
            _submitText(text);
          }
        },
        onTextChanged: (text) {
          // Update manual input with voice result
          _textController.text = text;
          setState(() {});
        },
        size: 72,
        showText: true,
        tooltip: widget.hintText,
      ),
    );
  }

  Widget _buildManualInputSection(BuildContext context) {
    return TextField(
      controller: _textController,
      autofocus: true,
      maxLines: 3,
      minLines: 1,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Type your message here...',
        border: const OutlineInputBorder(),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (text) {
        setState(() {}); // Update UI for submit button
      },
      onSubmitted: (text) {
        if (text.isNotEmpty) {
          _submitText(text);
        }
      },
    );
  }

  void _submitText(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      widget.onTextSubmitted(trimmedText);
    }
  }
}

/// Extension to easily show voice input dialog
extension VoiceInputDialogExtension on BuildContext {
  Future<String?> showVoiceInputDialog({
    required String title,
    String? subtitle,
    String? hintText,
  }) {
    return VoiceInputDialog.show(
      context: this,
      title: title,
      subtitle: subtitle,
      hintText: hintText,
    );
  }
}