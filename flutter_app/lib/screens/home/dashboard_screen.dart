import 'package:flutter/material.dart';
import '../projects/projects_feed_screen.dart';
import '../projects/create_project_screen.dart';
import '../profile/profile_screen.dart';
import '../feed/discovery_screen.dart';
import '../community/community_hub_screen.dart';
import '../community/create_discussion_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/layout_constants.dart';

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

  Widget? _buildFab(BuildContext context) {
    switch (_currentIndex) {
      case 0:
      case 1:
        return _fab(
          icon: Icons.add,
          label: 'Create',
          onPressed: () => setState(() => _currentIndex = 2),
        );
      case 3:
        return _fab(
          icon: Icons.edit_outlined,
          label: 'New Discussion',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateDiscussionScreen()),
          ),
        );
      default:
        return null;
    }
  }

  FloatingActionButton _fab({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.electricBlue,
      foregroundColor: AppColors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: LayoutConstants.bottomNavHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFF252528), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: _currentIndex, onTap: _onNavTap),
            _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Discover', index: 1, currentIndex: _currentIndex, onTap: _onNavTap),
            _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle_rounded, label: 'Create', index: 2, currentIndex: _currentIndex, onTap: _onNavTap),
            _NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community', index: 3, currentIndex: _currentIndex, onTap: _onNavTap),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: _currentIndex, onTap: _onNavTap),
          ],
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

/// Custom bottom navigation item with brand-colored active state and top-pill indicator.
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
    final iconColor =
        isActive ? AppColors.brightCyan : const Color(0xFF6B6B6E);
    final labelColor =
        isActive ? AppColors.brightCyan : const Color(0xFF6B6B6E);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill at the top
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 24 : 0,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.brightCyan,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: labelColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
