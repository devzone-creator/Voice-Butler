import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Advanced Mode Section
              _buildSectionHeader(context, 'Advanced Features'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Advanced Mode'),
                      subtitle: Text(
                        settingsProvider.isAdvancedMode
                            ? 'Access to rule building and preset workflows'
                            : 'Enable advanced automation features',
                      ),
                      value: settingsProvider.isAdvancedMode,
                      onChanged: (value) async {
                        await _showAdvancedModeDialog(context, value, settingsProvider);
                      },
                      secondary: Icon(
                        settingsProvider.isAdvancedMode
                            ? Icons.engineering
                            : Icons.settings,
                        color: settingsProvider.isAdvancedMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (settingsProvider.isAdvancedMode) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.rule),
                        title: const Text('Custom Rules'),
                        subtitle: Text('${settingsProvider.customRulesCount} active rules'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToRuleBuilder(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: const Text('Preset Workflows'),
                        subtitle: const Text('Pre-configured automation bundles'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToPresetWorkflows(context),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Automation Settings Section
              _buildSectionHeader(context, 'Automation'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive notifications for automated actions'),
                      value: settingsProvider.notificationsEnabled,
                      onChanged: settingsProvider.setNotificationsEnabled,
                      secondary: const Icon(Icons.notifications),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Background Processing'),
                      subtitle: const Text('Allow automation to run in background'),
                      value: settingsProvider.backgroundProcessingEnabled,
                      onChanged: settingsProvider.setBackgroundProcessingEnabled,
                      secondary: const Icon(Icons.schedule),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Default Reminder Delay'),
                      subtitle: Text('${settingsProvider.defaultReminderDelayMinutes} minutes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showReminderDelayDialog(context, settingsProvider),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Storage Settings Section
              _buildSectionHeader(context, 'Storage'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Activity Log Storage'),
                      subtitle: Text(
                        '${settingsProvider.activityLogCount} logs (${settingsProvider.storageUsagePercentage.toStringAsFixed(1)}% full)',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showStorageManagementDialog(context, settingsProvider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cleaning_services),
                      title: const Text('Auto Cleanup'),
                      subtitle: Text('Remove logs older than ${settingsProvider.maxLogRetentionDays} days'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showCleanupSettingsDialog(context, settingsProvider),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // AI Configuration Section
              _buildSectionHeader(context, 'AI Configuration'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Gemini API Key'),
                      subtitle: Text(
                        settingsProvider.hasGeminiApiKey
                            ? 'API key configured'
                            : 'Configure API key for AI features',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showApiKeyDialog(context, settingsProvider),
                    ),
                    if (settingsProvider.hasGeminiApiKey) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('AI Status'),
                        subtitle: Text(
                          settingsProvider.hasGeminiApiKey
                              ? 'AI features enabled'
                              : 'AI features disabled',
                        ),
                        trailing: Icon(
                          settingsProvider.hasGeminiApiKey
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: settingsProvider.hasGeminiApiKey
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // About Section
              _buildSectionHeader(context, 'About'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info),
                      title: Text('App Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showHelpDialog(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showAdvancedModeDialog(
    BuildContext context,
    bool newValue,
    SettingsProvider settingsProvider,
  ) async {
    if (newValue) {
      // Enabling Advanced Mode - show confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Advanced Mode'),
          content: const Text(
            'Advanced Mode provides access to custom rule building and preset workflows. '
            'This includes more complex automation features that require technical understanding.\n\n'
            'Are you sure you want to enable Advanced Mode?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await settingsProvider.setAdvancedMode(true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advanced Mode enabled! New features are now available.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Disabling Advanced Mode - show warning
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Advanced Mode'),
          content: const Text(
            'Disabling Advanced Mode will hide custom rule building and preset workflow features. '
            'Your existing custom rules will remain active but won\'t be editable.\n\n'
            'Are you sure you want to disable Advanced Mode?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await settingsProvider.setAdvancedMode(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advanced Mode disabled. Custom rules remain active.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _navigateToRuleBuilder(BuildContext context) {
    context.push('/rule-builder');
  }

  void _navigateToPresetWorkflows(BuildContext context) {
    // TODO: Navigate to preset workflows screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset Workflows - Coming Soon')),
    );
  }

  Future<void> _showReminderDelayDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final controller = TextEditingController(
      text: settingsProvider.defaultReminderDelayMinutes.toString(),
    );
    
    final newDelay = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Reminder Delay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the default delay for automation reminders (in minutes):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0 && value <= 1440) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newDelay != null) {
      await settingsProvider.setDefaultReminderDelayMinutes(newDelay);
    }
  }

  Future<void> _showStorageManagementDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Logs: ${settingsProvider.activityLogCount}'),
            Text('Storage Usage: ${settingsProvider.storageUsagePercentage.toStringAsFixed(1)}%'),
            Text('Max Logs: ${settingsProvider.maxLogsToKeep}'),
            const SizedBox(height: 16),
            const Text('Storage is automatically managed to keep recent activity while removing old logs.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await settingsProvider.performManualCleanup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manual cleanup completed')),
                );
              }
            },
            child: const Text('Clean Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCleanupSettingsDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final controller = TextEditingController(
      text: settingsProvider.maxLogRetentionDays.toString(),
    );
    
    final newDays = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Cleanup Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Automatically remove activity logs older than:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Days',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 7 && value <= 365) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newDays != null) {
      await settingsProvider.setMaxLogRetentionDays(newDays);
    }
  }

  Future<void> _showApiKeyDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final controller = TextEditingController(
      text: settingsProvider.geminiApiKey ?? '',
    );
    
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key to enable AI-powered task extraction and automation features.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                helperText: 'Your API key is stored locally',
              ),
              obscureText: true,
              obscuringCharacter: '•',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Clear the field
                controller.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (saved == true) {
      final apiKey = controller.text.trim();
      await settingsProvider.setGeminiApiKey(apiKey.isEmpty ? null : apiKey);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiKey.isEmpty
                  ? 'API key removed'
                  : 'API key saved successfully. Please restart the app for changes to take effect.',
            ),
            backgroundColor: apiKey.isEmpty ? Colors.orange : Colors.green,
          ),
        );
      }
    }
    
    controller.dispose();
  }

  Future<void> _showHelpDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Butler - Intelligent Task Management'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Voice-activated task creation'),
            Text('• AI-powered intent extraction'),
            Text('• Automated task management'),
            Text('• Advanced automation rules'),
            Text('• Activity monitoring'),
            SizedBox(height: 16),
            Text('For support, please check the documentation or contact support.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}