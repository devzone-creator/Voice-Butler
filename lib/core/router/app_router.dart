import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/recently_deleted_screen.dart';
import '../../features/automation/screens/activity_feed_screen.dart';
import '../../features/automation/screens/rule_builder_screen.dart';
import '../../features/automation/screens/preset_workflows_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../core/models/automation_rule.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/recently-deleted',
        name: 'recently-deleted',
        builder: (context, state) => const RecentlyDeletedScreen(),
      ),
      GoRoute(
        path: '/activity-feed',
        name: 'activity-feed',
        builder: (context, state) => const ActivityFeedScreen(),
      ),
      GoRoute(
        path: '/rule-builder',
        name: 'rule-builder',
        builder: (context, state) {
          final existingRule = state.extra as AutomationRule?;
          return RuleBuilderScreen(existingRule: existingRule);
        },
      ),
      GoRoute(
        path: '/preset-workflows',
        name: 'preset-workflows',
        builder: (context, state) => const PresetWorkflowsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.toString()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}