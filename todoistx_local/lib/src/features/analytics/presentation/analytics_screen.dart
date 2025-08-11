import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todoistx_local/src/features/analytics/data/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsData = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Your Week in Review', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (analyticsData.weeklyCompletedTasks.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                        return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat.E().format(day)));
                      },
                      reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: analyticsData.weeklyCompletedTasks
                    .asMap()
                    .map((i, y) => MapEntry(
                          i,
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(toY: y.toDouble(), color: theme.colorScheme.primary, width: 16)
                          ]),
                        ))
                    .values
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 48),
          Text('Productivity Streak', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 48),
                  const SizedBox(width: 16),
                  Text('${analyticsData.currentStreak} Day Streak', style: theme.textTheme.headlineMedium),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
