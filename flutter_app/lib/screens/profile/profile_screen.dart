import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/projects_service.dart';
import '../../models/user_model.dart';
import '../../models/project_model.dart';
import '../../main.dart';
import '../../widgets/video_player_dialog.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  User? _userProfile;
  List<Project> _userProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? 'User';
      final userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      final userId = prefs.getString('userId') ?? '';

      User? profile;
      List<Project> projects = [];
      if (userId.isNotEmpty) {
        try {
          final results = await Future.wait([
            UserService.getProfile(userId),
            ProjectsService.getUserProjects(userId),
          ]);
          profile = results[0] as User;
          projects = results[1] as List<Project>;
        } catch (e) {
          debugPrint('Failed to load profile data: $e');
        }
      }

      setState(() {
        _userName = userName;
        _userEmail = userEmail;
        _userProfile = profile;
        _userProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await UserService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleEditProfile() async {
    if (_userProfile == null) return;

    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _userProfile!),
      ),
    );

    if (updated != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', updated.name);
      setState(() {
        _userProfile = updated;
        _userName = updated.name;
      });
    }
  }

  int get _activeProjectsCount {
    return _userProjects.where((p) => p.status == 'open').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          if (_userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _handleEditProfile,
              tooltip: 'Edit Profile',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile header
                    _buildProfileHeader(),
                    const SizedBox(height: 32),

                    // Stats
                    _buildStats(),
                    const SizedBox(height: 32),

                    // Projects section
                    _buildProjectsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _userProfile?.name ?? _userName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final avatarUrl = _userProfile?.avatarUrl;

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF6366F1),
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
          child: avatarUrl == null
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          _userEmail,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),

        // Bio
        if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _userProfile!.bio!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Location
        if (_userProfile?.location != null &&
            _userProfile!.location!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _userProfile!.location!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            _userProjects.length.toString(),
            Icons.folder_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Projects',
            _activeProjectsCount.toString(),
            Icons.folder_open,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Projects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (_userProjects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first project!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userProjects.length,
            itemBuilder: (context, index) {
              final project = _userProjects[index];
              return _buildProjectCard(project);
            },
          ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final statusColor = project.status == 'open' ? Colors.green : Colors.grey;
    final statusText = project.status == 'open' ? 'Active' : project.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          if (project.videoUrl != null)
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (context) => VideoPlayerDialog(
                  videoUrl: project.videoUrl!,
                  projectTitle: project.title,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    project.thumbnailUrl != null
                        ? Image.network(
                            project.thumbnailUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 160,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.video_library,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.video_library,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black54,
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Skills
                if (project.requiredSkills.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: project.requiredSkills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
