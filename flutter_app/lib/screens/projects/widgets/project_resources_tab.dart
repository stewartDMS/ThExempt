import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/project_model.dart';
import '../../../theme/app_colors.dart';
import '../../../models/resource.dart';
import '../../../services/integrations_service.dart';

class ProjectResourcesTab extends StatefulWidget {
  final Project project;

  const ProjectResourcesTab({super.key, required this.project});

  @override
  State<ProjectResourcesTab> createState() => _ProjectResourcesTabState();
}

class _ProjectResourcesTabState extends State<ProjectResourcesTab> {
  List<Integration> _integrations = [];
  // Placeholder resource list
  final List<Resource> _resources = [];

  @override
  void initState() {
    super.initState();
    _loadIntegrations();
  }

  Future<void> _loadIntegrations() async {
    try {
      final integrations =
          await IntegrationsService.getIntegrations(widget.project.id);
      if (mounted) setState(() => _integrations = integrations);
    } catch (_) {}
  }

  List<Resource> get _documents =>
      _resources.where((r) => r.type == ResourceType.document).toList();
  List<Resource> get _links =>
      _resources.where((r) => r.type == ResourceType.link).toList();
  List<Resource> get _videos =>
      _resources.where((r) => r.type == ResourceType.video).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadIntegrations();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.description_outlined,
            title: 'Documents',
            color: AppColors.deepRed,
            children: _documents.isEmpty
                ? [_emptyItem('No documents uploaded')]
                : _documents.map((r) => _resourceTile(r)).toList(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: Icons.link,
            title: 'Links',
            color: AppColors.electricBlue,
            children: _links.isEmpty
                ? [_emptyItem('No links added')]
                : _links.map((r) => _resourceTile(r)).toList(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: Icons.videocam_outlined,
            title: 'Videos',
            color: AppColors.rebellionOrange,
            children: _videos.isEmpty
                ? [_emptyItem('No videos uploaded')]
                : _videos.map((r) => _resourceTile(r)).toList(),
          ),
          const SizedBox(height: 12),
          _buildIntegrationsSection(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _emptyItem(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(message,
          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
    );
  }

  Widget _resourceTile(Resource resource) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _resourceIcon(resource),
      title: Text(resource.title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: resource.uploadedByName != null
          ? Text('By ${resource.uploadedByName}',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: resource.url != null || resource.fileUrl != null
          ? IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () async {
                final url =
                    resource.url ?? resource.fileUrl ?? '';
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            )
          : null,
    );
  }

  Widget _resourceIcon(Resource resource) {
    IconData icon;
    Color color;
    switch (resource.type) {
      case ResourceType.document:
        icon = Icons.description_outlined;
        color = AppColors.deepRed;
        break;
      case ResourceType.link:
        icon = Icons.link;
        color = AppColors.electricBlue;
        break;
      case ResourceType.video:
        icon = Icons.videocam_outlined;
        color = AppColors.rebellionOrange;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildIntegrationsSection() {
    final serviceInfo = {
      'github': (
        Icons.code,
        Colors.black87,
        'GitHub'
      ),
      'figma': (
        Icons.design_services_outlined,
        const Color(0xFFF24E1E),
        'Figma'
      ),
      'slack': (
        Icons.chat_bubble_outline,
        const Color(0xFF4A154B),
        'Slack'
      ),
      'trello': (
        Icons.view_kanban_outlined,
        const Color(0xFF0052CC),
        'Trello'
      ),
    };

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.integration_instructions_outlined,
                    size: 20),
                const SizedBox(width: 8),
                const Text('Connected Services',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ..._integrations.map((integration) {
              final info =
                  serviceInfo[integration.service];
              if (info == null) return const SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: info.$2.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.$1, color: info.$2, size: 18),
                ),
                title: Text(info.$3,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                trailing: integration.isConnected
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Connected',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w600)),
                      )
                    : TextButton(
                        onPressed: null,
                        child: const Text('Connect',
                            style: TextStyle(fontSize: 12)),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
