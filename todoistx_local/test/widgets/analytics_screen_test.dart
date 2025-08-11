import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoistx_local/src/features/analytics/data/analytics_provider.dart';
import 'package:todoistx_local/src/features/analytics/presentation/analytics_screen.dart';

void main() {
  testWidgets('AnalyticsScreen displays title and streak card', (WidgetTester tester) async {
    // Create mock data to be returned by the provider
    final mockAnalyticsData = AnalyticsData(
      weeklyCompletedTasks: [1, 2, 3, 4, 5, 6, 7],
      currentStreak: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(mockAnalyticsData),
        ],
        child: const MaterialApp(
          home: AnalyticsScreen(),
        ),
      ),
    );

    // Verify the AppBar title is displayed.
    expect(find.text('Productivity'), findsOneWidget);

    // Verify the streak card is displayed with the correct streak.
    expect(find.text('5 Day Streak'), findsOneWidget);

    // Verify that the chart is present.
    // A simple way is to check for a key or a type.
    expect(find.byType(BarChart), findsOneWidget);
  });
}
