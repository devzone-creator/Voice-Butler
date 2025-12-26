import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/automation/providers/automation_provider.dart';
import 'features/voice/providers/voice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize services
  await StorageService.instance.initialize();
  await NotificationService.instance.initialize();
  await BackgroundService.instance.initialize();
  
  runApp(const VoiceButlerApp());
}

class VoiceButlerApp extends StatelessWidget {
  const VoiceButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AutomationProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
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