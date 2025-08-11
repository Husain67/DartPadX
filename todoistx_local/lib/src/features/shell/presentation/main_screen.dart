import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todoistx_local/l10n/app_localizations.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        // Set the type to fixed to show all labels
        // (सभी लेबल दिखाने के लिए प्रकार को निश्चित पर सेट करें)
        type: BottomNavigationBarType.fixed,

        // Calculate the current index based on the route
        // (मार्ग के आधार पर वर्तमान सूचकांक की गणना करें)
        currentIndex: _calculateSelectedIndex(context),

        onTap: (int index) {
          _onItemTapped(index, context);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.allTasks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.today_outlined),
            activeIcon: const Icon(Icons.today),
            label: AppLocalizations.of(context)!.today,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month),
            label: AppLocalizations.of(context)!.calendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: AppLocalizations.of(context)!.projects,
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).location;
    if (location.startsWith('/today')) {
      return 1;
    }
    if (location.startsWith('/calendar')) {
      return 2;
    }
    if (location.startsWith('/projects')) {
      return 3;
    }
    return 0; // Default to Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/today');
        break;
      case 2:
        GoRouter.of(context).go('/calendar');
        break;
      case 3:
        GoRouter.of(context).go('/projects');
        break;
    }
  }
}
