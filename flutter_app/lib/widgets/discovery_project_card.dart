import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../utils/time_ago.dart';
import 'team_composition_indicator.dart';
import 'video_player_dialog.dart';

/// Enhanced project card for the discovery screen.
/// Optionally displays a match percentage badge, open-role chips, a team
/// composition indicator, and a "Perfect match!" banner for ≥90 % matches.
class DiscoveryProjectCard extends StatelessWidget {
  final Project project;

  /// 0–100 match score (null = not calculated / user not logged in).
  final int? matchScore;

  /// Open role titles to preview on the card (max 3 shown).
  final List<String> openRoleTitles;

  const DiscoveryProjectCard({
    super.key,
    required this.project,
    this.matchScore,
    this.openRoleTitles = const [],
  });

  Color _matchColor(int score) {
    if (score >= 75) return Colors.green[600]!;
    if (score >= 50) return Colors.orange[600]!;
    return Colors.red[400]!;
  }

  void _openProject(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: project.ownerId),
      ),
    );
  }

  void _playVideo(BuildContext context) {
    if (project.videoUrl != null) {
      showDialog(
        context: context,
        builder: (_) => VideoPlayerDialog(
          videoUrl: project.videoUrl!,
          projectTitle: project.title,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPerfectMatch = matchScore != null && matchScore! >= 90;
    final openCount = project.totalRolesNeeded - project.rolesFilled;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPerfectMatch
              ? Colors.green[300]!
              : Colors.grey[300]!,
          width: isPerfectMatch ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _openProject(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfect-match banner
            if (isPerfectMatch)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Perfect match for you!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openOwnerProfile(context),
                        child: project.ownerAvatarUrl != null
                            ? CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    NetworkImage(project.ownerAvatarUrl!),
                                onBackgroundImageError: (_, __) {},
                              )
                            : Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    project.ownerName.isNotEmpty
                                        ? project.ownerName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _openOwnerProfile(context),
                              child: Text(
                                project.ownerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeAgo(project.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Match badge
                      if (matchScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _matchColor(matchScore!).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _matchColor(matchScore!).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            '$matchScore% match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _matchColor(matchScore!),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Video thumbnail
                  if (project.videoUrl != null)
                    GestureDetector(
                      onTap: () => _playVideo(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            project.thumbnailUrl != null
                                ? Image.network(
                                    project.thumbnailUrl!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _videoPlaceholder(),
                                  )
                                : _videoPlaceholder(),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.black54,
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (project.videoUrl != null) const SizedBox(height: 12),

                  // Title
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Skills chips
                  if (project.requiredSkills.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.requiredSkills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  if (project.requiredSkills.isNotEmpty)
                    const SizedBox(height: 12),

                  // Team composition indicator
                  TeamCompositionIndicator(
                    totalRoles: project.totalRolesNeeded,
                    filledRoles: project.rolesFilled,
                  ),

                  // Open roles preview
                  if (openRoleTitles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildOpenRolesPreview(openCount),
                  ] else if (openCount > 0) ...[
                    const SizedBox(height: 10),
                    _buildOpenRolesSummary(openCount),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      height: 160,
      color: Colors.grey[200],
      child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
    );
  }

  Widget _buildOpenRolesPreview(int openCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline, size: 13, color: Colors.green[700]),
            const SizedBox(width: 4),
            Text(
              '$openCount open role${openCount == 1 ? '' : 's'}:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: openRoleTitles.take(3).map((title) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpenRolesSummary(int openCount) {
    return Row(
      children: [
        Icon(Icons.group_outlined, size: 13, color: Colors.green[700]),
        const SizedBox(width: 4),
        Text(
          '$openCount open role${openCount == 1 ? '' : 's'} available',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }
}
