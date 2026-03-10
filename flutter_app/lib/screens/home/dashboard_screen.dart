import 'package:flutter/material.dart';
import '../projects/projects_feed_screen.dart';
import '../projects/create_project_screen.dart';
import '../profile/profile_screen.dart';
import '../feed/discovery_screen.dart';
import '../community/community_hub_screen.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;
  final GlobalKey<ProjectsFeedScreenState> _feedKey = GlobalKey();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      ProjectsFeedScreen(key: _feedKey),
      const DiscoveryScreen(),
      const CreateProjectScreen(),
      const CommunityHubScreen(),
      const ProfileScreen(),
    ];
  }

  void _refreshFeed() {
    _feedKey.currentState?.refreshProjects();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = _currentIndex == 2;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: isCreate
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 4,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withAlpha(128),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, currentIndex: _currentIndex, onTap: _onNavTap),
              _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Discover', index: 1, currentIndex: _currentIndex, onTap: _onNavTap),
              _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Create', index: 2, currentIndex: _currentIndex, onTap: _onNavTap),
              _NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum, label: 'Community', index: 3, currentIndex: _currentIndex, onTap: _onNavTap),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 4, currentIndex: _currentIndex, onTap: _onNavTap),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    final wasOnHome = _currentIndex == 0;
    setState(() {
      _currentIndex = index;
    });
    if (index == 0 && !wasOnHome) {
      _refreshFeed();
    }
  }
}

/// Custom bottom navigation item with scale animation on tap
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.primary : AppColors.grey400;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
