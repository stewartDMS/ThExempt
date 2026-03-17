import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Landing page shown to unauthenticated users.
/// Features a hero section, feature highlights, how-it-works steps,
/// statistics, and a call-to-action section.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(),
            _buildHowItWorksSection(),
            _buildStatsSection(),
            _buildCTASection(context),
          ],
        ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            Color(0xFF7B61FF),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Build Your Next\nProject',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Connect with talented collaborators, share ideas,\nand bring your projects to life.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.88),
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),

              // CTA buttons
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _HeroButton(
                    label: 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onPressed: () => _navigateTo(context, 'signup'),
                  ),
                  _HeroButton(
                    label: 'Sign In',
                    icon: Icons.login_rounded,
                    filled: false,
                    onPressed: () => _navigateTo(context, 'login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String destination) {
    if (destination == 'signup') {
      Navigator.of(context).pushNamed('/signup');
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }

  // ── Features ──────────────────────────────────────────────────────────────

  Widget _buildFeaturesSection() {
    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Everything You Need',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'One platform to ideate, collaborate, and ship.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(
                Icons.people_outline_rounded,
                'Find Collaborators',
                'Connect with talented individuals who share your vision and want to build together.',
                AppColors.primary,
              ),
              _buildFeatureCard(
                Icons.lightbulb_outline_rounded,
                'Share Ideas',
                'Post your projects and get meaningful feedback from a passionate community.',
                AppColors.warning,
              ),
              _buildFeatureCard(
                Icons.rocket_launch_outlined,
                'Launch Together',
                'Build amazing things with your team and take your ideas from concept to reality.',
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      IconData icon, String title, String description, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── How It Works ──────────────────────────────────────────────────────────

  Widget _buildHowItWorksSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
      child: Column(
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildStep(
            1,
            'Create Your Profile',
            'Tell us about your skills, interests, and what kind of projects excite you.',
            AppColors.primary,
          ),
          _buildStep(
            2,
            'Discover Projects',
            'Browse exciting projects looking for collaborators just like you.',
            AppColors.warning,
          ),
          _buildStep(
            3,
            'Join & Build',
            'Connect with teams, contribute your skills, and start creating something great.',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Join a Growing Community',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 40,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildStat('1,000+', 'Projects', AppColors.primary),
              _buildStat('5,000+', 'Members', AppColors.success),
              _buildStat('10,000+', 'Connections', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String number, String label, Color color) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.grey500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7B61FF)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Get Started?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of creators building amazing projects together.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.88),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _HeroButton(
            label: 'Create Free Account',
            icon: Icons.arrow_forward_rounded,
            filled: true,
            onPressed: () => Navigator.of(context).pushNamed('/signup'),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/login'),
            child: Text(
              'Already have an account? Sign in →',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
