import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_endorsement_model.dart';
import '../../../services/projects_service.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

class ProjectEndorsementsTab extends StatefulWidget {
  final Project project;
  final String? currentUserId;
  final void Function(Project)? onProjectUpdated;

  const ProjectEndorsementsTab({
    super.key,
    required this.project,
    this.currentUserId,
    this.onProjectUpdated,
  });

  @override
  State<ProjectEndorsementsTab> createState() => _ProjectEndorsementsTabState();
}

class _ProjectEndorsementsTabState extends State<ProjectEndorsementsTab> {
  List<ProjectEndorsement> _endorsements = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEndorsed = false;
  bool _endorseLoading = false;

  late int _endorsementsCount;

  @override
  void initState() {
    super.initState();
    _endorsementsCount = widget.project.endorsementsCount;
    _isEndorsed = widget.project.isEndorsedByUser;
    _loadEndorsements();
  }

  Future<void> _loadEndorsements() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        ProjectsService.getEndorsements(widget.project.id),
        if (widget.currentUserId != null)
          ProjectsService.hasUserEndorsed(widget.project.id),
      ]);
      if (mounted) {
        setState(() {
          _endorsements = results[0] as List<ProjectEndorsement>;
          if (widget.currentUserId != null && results.length > 1) {
            _isEndorsed = results[1] as bool;
          }
          _endorsementsCount = _endorsements.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _toggleEndorsement() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to endorse this project')),
      );
      return;
    }
    // Prevent endorsing own project
    if (widget.currentUserId == widget.project.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot endorse your own project')),
      );
      return;
    }

    setState(() => _endorseLoading = true);
    try {
      if (_isEndorsed) {
        await ProjectsService.unendorseProject(widget.project.id);
        setState(() {
          _isEndorsed = false;
          _endorsementsCount = (_endorsementsCount - 1).clamp(0, 999999);
        });
      } else {
        // Optionally ask for a message
        String? message;
        if (mounted) {
          message = await _askForMessage();
        }
        await ProjectsService.endorseProject(
          widget.project.id,
          message: message,
        );
        setState(() {
          _isEndorsed = true;
          _endorsementsCount += 1;
        });
      }
      await _loadEndorsements();
      // Notify parent so stats update
      widget.onProjectUpdated?.call(
        widget.project.copyWith(
          endorsementsCount: _endorsementsCount,
          isEndorsedByUser: _isEndorsed,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _endorseLoading = false);
    }
  }

  Future<String?> _askForMessage() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Endorse this project'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add an optional message (why you endorse this)…',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Endorse'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadEndorsements,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildEndorseHeader()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Failed to load endorsements'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadEndorsements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_endorsements.isEmpty)
            const SliverFillRemaining(
              child: _EmptyEndorsements(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _EndorsementCard(endorsement: _endorsements[i]),
                childCount: _endorsements.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEndorseHeader() {
    final isOwner = widget.currentUserId == widget.project.ownerId;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Big endorsement count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_up_alt_rounded,
                  size: 32,
                  color: _isEndorsed ? AppColors.primary : Colors.grey[400]),
              const SizedBox(width: 10),
              Text(
                '$_endorsementsCount',
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                _endorsementsCount == 1 ? 'Endorsement' : 'Endorsements',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isOwner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _endorseLoading ? null : _toggleEndorsement,
                icon: _endorseLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEndorsed
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined),
                label: Text(_isEndorsed
                    ? 'Endorsed ✓'
                    : 'Endorse this project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEndorsed
                      ? AppColors.primary
                      : null,
                  foregroundColor: _isEndorsed ? Colors.white : null,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (_endorsements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Community endorsements',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndorsementCard extends StatelessWidget {
  final ProjectEndorsement endorsement;

  const _EndorsementCard({required this.endorsement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
                endorsement.userAvatarUrl != null &&
                        endorsement.userAvatarUrl!.isNotEmpty
                    ? NetworkImage(endorsement.userAvatarUrl!)
                    : null,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: endorsement.userAvatarUrl == null ||
                    endorsement.userAvatarUrl!.isEmpty
                ? Text(
                    endorsement.userName.isNotEmpty
                        ? endorsement.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(endorsement.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(
                      timeAgo(endorsement.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                if (endorsement.message != null &&
                    endorsement.message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    endorsement.message!,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEndorsements extends StatelessWidget {
  const _EmptyEndorsements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No endorsements yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to show your support!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
