import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/project_model.dart';

class ProjectAnalyticsTab extends StatelessWidget {
  final Project project;

  const ProjectAnalyticsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEngagementSummary(),
          const SizedBox(height: 16),
          _buildViewsChart(),
          const SizedBox(height: 16),
          _buildTeamRolesChart(),
        ],
      ),
    );
  }

  Widget _buildEngagementSummary() {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _engagementItem(
                  Icons.visibility_outlined,
                  '${project.viewsCount ?? 0}',
                  'Views',
                  Colors.teal,
                  project.viewsTrend,
                ),
                _engagementItem(
                  Icons.thumb_up_outlined,
                  '${project.likesCount ?? 0}',
                  'Likes',
                  Colors.pink,
                  null,
                ),
                _engagementItem(
                  Icons.inbox_outlined,
                  '${project.applicationsCount ?? 0}',
                  'Applications',
                  Colors.indigo,
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _engagementItem(
    IconData icon,
    String value,
    String label,
    Color color,
    double? trend,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[600])),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  trend >= 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 12,
                  color: trend >= 0 ? Colors.green : Colors.red,
                ),
                Text(
                  '${trend.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: trend >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewsChart() {
    // Generate placeholder chart data (7 days)
    final spots = List.generate(7, (i) {
      final base = (project.viewsCount ?? 10).toDouble();
      final noise = (i % 3 == 0 ? 1.3 : 0.8) * (i + 1);
      return FlSpot(i.toDouble(), (base * noise / 7).clamp(1, 100));
    });

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Views (last 7 days)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const days = [
                            'M', 'T', 'W', 'T', 'F', 'S', 'S'
                          ];
                          final idx = v.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(days[idx],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600]));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRolesChart() {
    final filled = project.rolesFilled.toDouble();
    final open = (project.totalRolesNeeded - project.rolesFilled)
        .clamp(0, project.totalRolesNeeded)
        .toDouble();

    if (filled == 0 && open == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Composition',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: filled,
                      title:
                          '${filled.toInt()}\nFilled',
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      radius: 50,
                    ),
                    if (open > 0)
                      PieChartSectionData(
                        color: Colors.grey[300]!,
                        value: open,
                        title: '${open.toInt()}\nOpen',
                        titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700]),
                        radius: 50,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
