import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/activity_item.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

class ProjectActivityTab extends StatefulWidget {
  final Project project;

  const ProjectActivityTab({super.key, required this.project});

  @override
  State<ProjectActivityTab> createState() => _ProjectActivityTabState();
}

class _ProjectActivityTabState extends State<ProjectActivityTab> {
  // Placeholder activity list (a real impl would fetch from Supabase)
  final List<ActivityItem> _activities = [];
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _loading = false);
  }

  /// Group activities by time bucket.
  Map<String, List<ActivityItem>> _groupByDate(
      List<ActivityItem> items) {
    final now = DateTime.now();
    final groups = <String, List<ActivityItem>>{};

    for (final item in items) {
      final diff = now.difference(item.timestamp);
      String bucket;
      if (diff.inDays == 0) {
        bucket = 'Today';
      } else if (diff.inDays == 1) {
        bucket = 'Yesterday';
      } else if (diff.inDays <= 7) {
        bucket = 'This Week';
      } else {
        bucket = 'This Month';
      }
      groups.putIfAbsent(bucket, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activity will appear here as your project progresses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final groups = _groupByDate(_activities);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: groups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...entry.value.map((a) => _ActivityTile(activity: a)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or emoji
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: activity.userAvatar != null
                    ? NetworkImage(activity.userAvatar!)
                    : null,
                backgroundColor: AppColors.primaryContainer,
                child: activity.userAvatar == null
                    ? Text(
                        activity.userName.isNotEmpty
                            ? activity.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricBlue,
                            fontSize: 14),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    activity.typeEmoji,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: activity.message),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(activity.timestamp),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
