import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'core/services/serverpod_client.dart';
import 'core/services/backend_ai_service.dart';

import 'features/tasks/providers/task_provider.dart';
import 'features/voice/providers/voice_provider.dart';
import 'features/ai/providers/ai_provider.dart';
// import 'features/automation/providers/automation_provider.dart';
// import 'features/automation/providers/rule_builder_provider.dart';
// import 'features/automation/providers/preset_workflow_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize services
  await StorageService.instance.initialize();
  await NotificationService.instance.initialize();
  
  // Initialize Serverpod client and backend AI service
  await ServerpodClientService.instance.initialize();
  await BackendAIService.instance.initialize();
  
  // Initialize background service (web-compatible)
  try {
    await BackgroundService.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Background service initialization failed: $e');
    }
  }
  
  runApp(const VoiceButlerApp());
}

class VoiceButlerApp extends StatelessWidget {
  const VoiceButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        // Temporarily disabled for demo
        // ChangeNotifierProvider(create: (_) => AutomationProvider()),
        // ChangeNotifierProvider(create: (_) => RuleBuilderProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // ChangeNotifierProxyProvider<AutomationProvider, PresetWorkflowProvider>(
        //   create: (context) => PresetWorkflowProvider(
        //     Provider.of<AutomationProvider>(context, listen: false),
        //   ),
        //   update: (context, automationProvider, previous) =>
        //       previous ?? PresetWorkflowProvider(automationProvider),
        // ),
      ],
      builder: (context, child) {
        // Automation temporarily disabled for demo
        return child!;
      },
      child: MaterialApp.router(
        title: 'Voice Butler',
        theme: AppConfig.lightTheme,
        darkTheme: AppConfig.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}