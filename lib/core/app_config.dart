import 'package:flutter/material.dart';

class AppConfig {
  // App Constants
  static const String appName = 'Voice Butler';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tasksBoxKey = 'tasks';
  static const String automationRulesBoxKey = 'automation_rules';
  static const String activityLogsBoxKey = 'activity_logs';
  static const String settingsBoxKey = 'settings';
  
  // Soft Delete Configuration
  static const int softDeleteRetentionDays = 7;
  
  // AI Configuration
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiModel = 'gemini-pro';
  
  // Notification Configuration
  static const String notificationChannelId = 'voice_butler_notifications';
  static const String notificationChannelName = 'Voice Butler';
  static const String notificationChannelDescription = 'Task reminders and automation notifications';
  
  // Background Job Configuration
  static const String cleanupJobName = 'cleanup_old_tasks';
  static const String reminderJobName = 'task_reminders';
  
  // Theme Configuration
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}