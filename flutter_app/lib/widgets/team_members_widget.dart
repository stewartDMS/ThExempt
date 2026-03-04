import 'package:flutter/material.dart';
import '../models/project_member_model.dart';
import '../services/projects_service.dart';

class TeamMembersWidget extends StatefulWidget {
  final String projectId;

  const TeamMembersWidget({
    super.key,
    required this.projectId,
  });

  @override
  State<TeamMembersWidget> createState() => _TeamMembersWidgetState();
}

class _TeamMembersWidgetState extends State<TeamMembersWidget> {
  List<ProjectMember> _members = [];
  bool _isLoading = true;

  // Category color map
  static const Map<String, Color> _categoryColors = {
    'Technical': Color(0xFF3B82F6),
    'Business': Color(0xFF10B981),
    'Marketing': Color(0xFFF59E0B),
    'Operations': Color(0xFF8B5CF6),
    'Creative': Color(0xFFEC4899),
    'Legal': Color(0xFF6366F1),
    'Domain': Color(0xFFEF4444),
    'Soft Skills': Color(0xFF06B6D4),
  };

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members =
          await ProjectsService.getProjectMembers(widget.projectId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<ProjectMember>> get _membersByCategory {
    final map = <String, List<ProjectMember>>{};
    for (final m in _members) {
      final cat = m.roleCategory.isNotEmpty ? m.roleCategory : 'Other';
      map.putIfAbsent(cat, () => []).add(m);
    }
    return map;
  }

  Color _colorForCategory(String category) =>
      _categoryColors[category] ?? const Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_members.isEmpty) return const SizedBox.shrink();

    final byCategory = _membersByCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Team Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_members.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...byCategory.entries.map((entry) {
          final color = _colorForCategory(entry.key);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category label
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ),
              // Member tiles
              ...entry.value.map((member) => _MemberTile(
                    member: member,
                    accentColor: color,
                  )),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ProjectMember member;
  final Color accentColor;

  const _MemberTile({
    required this.member,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accentColor.withOpacity(0.15),
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: accentColor, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  member.roleTitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.verified, size: 16, color: accentColor.withOpacity(0.7)),
        ],
      ),
    );
  }
}
