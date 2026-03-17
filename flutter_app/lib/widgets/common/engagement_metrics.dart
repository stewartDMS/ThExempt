import 'package:flutter/material.dart';

/// Displays a horizontal row of engagement metrics (views, likes, comments,
/// applications).  Pass null to omit a metric.
class EngagementMetrics extends StatelessWidget {
  final int? views;
  final int? likes;
  final int? comments;
  final int? applications;

  const EngagementMetrics({
    super.key,
    this.views,
    this.likes,
    this.comments,
    this.applications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (views != null)
          _buildMetric(Icons.visibility_outlined, views!, Colors.grey),
        if (likes != null)
          _buildMetric(Icons.favorite_border, likes!, Colors.red),
        if (comments != null)
          _buildMetric(Icons.chat_bubble_outline, comments!, Colors.blue),
        if (applications != null)
          _buildMetric(Icons.description_outlined, applications!, Colors.green),
      ],
    );
  }

  Widget _buildMetric(IconData icon, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
