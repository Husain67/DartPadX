import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todoistx_local/src/features/shell/presentation/main_screen.dart';
import 'package:todoistx_local/src/features/projects/presentation/add_edit_project_screen.dart';
import 'package:todoistx_local/src/features/calendar/presentation/calendar_screen.dart';
import 'package:todoistx_local/src/features/projects/presentation/project_list_screen.dart';
import 'package:todoistx_local/src/features/settings/presentation/settings_screen.dart';
import 'package:todoistx_local/src/features/tasks/presentation/add_edit_task_screen.dart';
import 'package:todoistx_local/src/features/analytics/presentation/analytics_screen.dart';
import 'package:todoistx_local/src/features/tasks/presentation/home_screen.dart';
import 'package:todoistx_local/src/features/tasks/presentation/today_screen.dart';

// Navigator key for the shell
// (शेल के लिए नेविगेटर कुंजी)
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// GoRouter configuration
// (GoRouter कॉन्फ़िगरेशन)
final goRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: GlobalKey<NavigatorState>(), // Root navigator key
  routes: [
    // The main screen with the bottom navigation bar
    // (नीचे नेविगेशन बार के साथ मुख्य स्क्रीन)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectListScreen(),
        ),
      ],
    ),

    // Routes that will cover the main screen (no bottom nav bar)
    // (वे मार्ग जो मुख्य स्क्रीन को कवर करेंगे (कोई नीचे नव बार नहीं))
    GoRoute(
      path: '/project/:id',
      builder: (context, state) {
        final projectId = state.pathParameters['id'];
        if (projectId == null) {
          return const Scaffold(body: Center(child: Text('Error: Project ID is missing')));
        }
        return AddEditProjectScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) {
        final taskId = state.pathParameters['id'];
        if (taskId == null) {
          // This should not happen if the route is matched correctly
          return const Scaffold(
            body: Center(child: Text('Error: Task ID is missing')),
          );
        }
        return AddEditTaskScreen(taskId: taskId);
      },
    ),
  ],
);
