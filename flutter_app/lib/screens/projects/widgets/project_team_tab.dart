import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_member_model.dart';
import '../../../services/projects_service.dart';
import '../applications_screen.dart';

class ProjectTeamTab extends StatefulWidget {
  final Project project;
  final bool isOwner;

  const ProjectTeamTab({
    super.key,
    required this.project,
    required this.isOwner,
  });

  @override
  State<ProjectTeamTab> createState() => _ProjectTeamTabState();
}

class _ProjectTeamTabState extends State<ProjectTeamTab> {
  List<ProjectMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members =
          await ProjectsService.getProjectMembers(widget.project.id);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMembersSection(),
          const SizedBox(height: 16),
          _buildOpenRolesSection(),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Members (${_members.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_members.isEmpty)
              Text('No team members yet.',
                  style: TextStyle(color: Colors.grey[600]))
            else
              ..._members.map((m) => _memberTile(m)),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(ProjectMember member) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: member.avatarUrl != null
            ? NetworkImage(member.avatarUrl!)
            : null,
        backgroundColor: Colors.indigo[100],
        child: member.avatarUrl == null
            ? Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              )
            : null,
      ),
      title: Text(member.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(member.roleTitle,
          style:
              TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          member.roleCategory,
          style:
              TextStyle(fontSize: 11, color: Colors.blue[700]),
        ),
      ),
    );
  }

  Widget _buildOpenRolesSection() {
    final openRoles =
        widget.project.totalRolesNeeded - widget.project.rolesFilled;
    if (openRoles <= 0) return const SizedBox.shrink();

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Open Positions',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$openRoles open',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$openRoles role${openRoles == 1 ? '' : 's'} still need to be filled.',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (widget.isOwner) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ApplicationsInboxScreen(
                        projectId: widget.project.id,
                        projectTitle: widget.project.title,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.inbox_outlined, size: 18),
                  label: const Text('View Applications'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
