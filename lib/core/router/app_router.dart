import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // TODO: Add other routes as screens are implemented
      // GoRoute(
      //   path: '/tasks',
      //   name: 'tasks',
      //   builder: (context, state) => const TaskListScreen(),
      // ),
      // GoRoute(
      //   path: '/activity-feed',
      //   name: 'activity-feed',
      //   builder: (context, state) => const ActivityFeedScreen(),
      // ),
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