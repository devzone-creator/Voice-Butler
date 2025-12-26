import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../voice/providers/voice_provider.dart';
import '../../voice/widgets/widgets.dart';
import '../../ai/providers/ai_provider.dart';
import '../../../core/models/task.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/ai_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Butler'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings when implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Voice Butler Logo/Icon placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.mic,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Welcome to Voice Butler',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Speak your tasks, let the Butler handle the rest',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Voice Input Widget
              VoiceInputWidget(
                onTextSubmitted: (text) => _handleVoiceInput(context, text),
                hintText: 'Say something like "Create a task to review the code"',
                labelText: 'Voice Input',
                showManualInput: true,
                autoFocusManualInput: false,
              ),
              
              const SizedBox(height: 32),
              
              // Quick Access Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tasks'),
                      icon: const Icon(Icons.list),
                      label: const Text('Tasks'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/activity-feed'),
                      icon: const Icon(Icons.history),
                      label: const Text('Activity'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickVoiceInput(context),
          tooltip: 'Quick Voice Input',
          child: const Icon(Icons.mic),
        ),
      ),
    );
  }

  void _handleVoiceInput(BuildContext context, String text) async {
    final aiProvider = context.read<AIProvider>();
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing your request...'),
          ],
        ),
      ),
    );

    try {
      // Extract task intent using AI
      TaskIntentResult result;
      
      if (aiProvider.hasApiKey && aiProvider.isInitialized) {
        result = await aiProvider.extractTaskIntent(text);
      } else {
        // Use fallback parsing if AI is not available
        result = aiProvider.fallbackTaskExtraction(text);
      }

      // Close processing dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        // Show task preview and confirmation
        _showTaskPreview(context, result, text);
      } else {
        // Show error
        _showError(context, result.error ?? 'Failed to process request');
      }
    } catch (e) {
      // Close processing dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      _showError(context, 'Unexpected error: $e');
    }
  }

  void _showTaskPreview(BuildContext context, TaskIntentResult result, String originalText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original: "$originalText"'),
            const SizedBox(height: 16),
            const Text('Extracted Task:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Title: ${result.title}'),
            Text('Priority: ${result.priority?.name.toUpperCase()}'),
            if (result.reason != null) Text('Reason: ${result.reason}'),
            if (result.deadline != null) 
              Text('Deadline: ${result.deadline!.toLocal().toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createTask(context, result);
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  void _createTask(BuildContext context, TaskIntentResult result) async {
    try {
      final task = Task.create(
        title: result.title!,
        priority: result.priority!,
        reason: result.reason,
        deadline: result.deadline,
      );

      await StorageService.instance.storeTask(task);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to create task: $e');
      }
    }
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
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

  Future<void> _showQuickVoiceInput(BuildContext context) async {
    final result = await context.showVoiceInputDialog(
      title: 'Quick Voice Input',
      subtitle: 'Speak or type your task',
      hintText: 'Create a task to...',
    );

    if (result != null && result.isNotEmpty) {
      _handleVoiceInput(context, result);
    }
  }
}