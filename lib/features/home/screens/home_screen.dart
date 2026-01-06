import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../voice/providers/voice_provider.dart';
import '../../voice/widgets/widgets.dart';
import '../../ai/providers/ai_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../core/services/backend_ai_service.dart';

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
              icon: const Icon(Icons.list),
              onPressed: () => context.push('/tasks'),
              tooltip: 'Tasks',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/activity-feed'),
              tooltip: 'Activity Feed',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Center(
          child: Padding(
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
              ],
            ),
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
      bool usedFallback = false;
      
      if (aiProvider.hasApiKey && aiProvider.isInitialized) {
        try {
          result = await aiProvider.extractTaskIntent(text);
        } catch (e) {
          // If AI fails, use fallback
          usedFallback = true;
          result = aiProvider.fallbackTaskExtraction(text);
        }
      } else {
        // Use fallback parsing if AI is not available
        usedFallback = true;
        result = aiProvider.fallbackTaskExtraction(text);
      }

      // Close processing dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        // Show task preview and confirmation (with note if fallback was used)
        _showTaskPreview(context, result, text);
      } else {
        // Even if extraction failed, try to create a basic task from the text
        // This ensures users can still create tasks even if AI fails
        final fallbackResult = aiProvider.fallbackTaskExtraction(text);
        if (fallbackResult.isSuccess) {
          _showTaskPreview(context, fallbackResult, text);
        } else {
          // Show error only if fallback also fails
          _showError(context, result.error ?? 'Failed to process request. Please try a different format.');
        }
      }
    } catch (e) {
      // Close processing dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Try fallback even on unexpected errors
      try {
        final fallbackResult = aiProvider.fallbackTaskExtraction(text);
        if (fallbackResult.isSuccess) {
          _showTaskPreview(context, fallbackResult, text);
        } else {
          _showError(context, 'Unexpected error: $e');
        }
      } catch (fallbackError) {
        _showError(context, 'Unexpected error: $e. Fallback also failed: $fallbackError');
      }
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
      final taskProvider = context.read<TaskProvider>();
      
      final task = await taskProvider.createTask(
        title: result.title!,
        priority: result.priority!,
        reason: result.reason,
        deadline: result.deadline,
      );

      if (context.mounted && task != null) {
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