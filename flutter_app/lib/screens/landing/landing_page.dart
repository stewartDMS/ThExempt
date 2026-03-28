import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Landing page shown to unauthenticated users.
///
/// Visual identity matches the public ThExempt marketing site:
/// dark charcoal/steelGray/deepRed palette, bold movement-first copy, and
/// the same section ordering as the Next.js landing page (Hero → Features →
/// How It Works → Stats → CTA).
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // ── Community stats shown in the social-proof section ─────────────────────
  static const String _statInvested = '\$2.5M+';
  static const String _statChangemakers = '10,234';
  static const String _statProjects = '234';
  static const String _statHours = '87K+';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
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
        minHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            AppColors.steelGray,
            AppColors.deepRed,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'WHERE CHANGE\nHAPPENS.',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'EVERYDAY PEOPLE\nMAKE IT HAPPEN.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'The old systems are broken.\nBut you have power. And we have a plan.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.82),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // CTA buttons
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  _HeroButton(
                    label: 'JOIN THE MOVEMENT',
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    onPressed: () => _navigateTo(context, 'signup'),
                  ),
                  _HeroButton(
                    label: 'SEE PROJECTS',
                    icon: Icons.play_circle_outline_rounded,
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
      color: AppColors.charcoal,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(
        children: [
          // Section label pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.35)),
            ),
            child: const Text(
              'EVERYTHING YOU NEED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.electricBlue,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
              children: [
                TextSpan(text: 'Built for\n'),
                TextSpan(
                  text: 'Ambitious Builders',
                  style: TextStyle(color: AppColors.electricBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Every tool you need to go from idea to shipped,\nwith the right team by your side.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.55),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(
                Icons.people_outline_rounded,
                'Find Collaborators',
                'Connect with talented changemakers who share your vision and want to build together.',
                AppColors.electricBlue,
              ),
              _buildFeatureCard(
                Icons.trending_up_outlined,
                'Fund Your Project',
                'Access membership credits, community investment, and equity tools for real impact.',
                AppColors.rebellionOrange,
              ),
              _buildFeatureCard(
                Icons.rocket_launch_outlined,
                'Launch Together',
                'Go from idea to shipped with milestones, tasks, and a team that believes in the mission.',
                AppColors.forestGreen,
              ),
              _buildFeatureCard(
                Icons.forum_outlined,
                'Discuss Systems',
                'Break down broken structures, share insights, and turn discussions into action.',
                AppColors.brightCyan,
              ),
              _buildFeatureCard(
                Icons.bar_chart_rounded,
                'Track Progress',
                'Project analytics, health scores, and milestone tracking keep everyone moving forward.',
                AppColors.warmAmber,
              ),
              _buildFeatureCard(
                Icons.pie_chart_outline_rounded,
                'Earn Equity',
                'Contribute your skills and time, and earn real shares in the projects you help build.',
                AppColors.deepRed,
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
      width: 268,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.steelGray.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── How It Works ──────────────────────────────────────────────────────────

  Widget _buildHowItWorksSection() {
    return Container(
      color: const Color(0xFF1A1A1A), // slightly lighter than charcoal
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
      child: Column(
        children: [
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.electricBlue,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Changemaker Journey',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildStep(
            1,
            'Create Your Profile',
            'Tell us your skills, experiences, and which systems you\'re ready to fix.',
            AppColors.electricBlue,
            AppColors.brightCyan,
          ),
          _buildStep(
            2,
            'Discover Projects',
            'Find changemakers already building solutions you believe in, or launch your own.',
            AppColors.rebellionOrange,
            AppColors.warmAmber,
          ),
          _buildStep(
            3,
            'Contribute & Build',
            'Invest credits, offer skills, join a team — and start creating something that matters.',
            AppColors.forestGreen,
            AppColors.brightCyan,
          ),
          _buildStep(
            4,
            'Earn Real Returns',
            'As projects succeed, your contributions convert to equity and shared wealth.',
            AppColors.deepRed,
            AppColors.rebellionOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description,
      Color colorA, Color colorB) {
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
                colors: [colorA, colorB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorA.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.55,
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
      color: AppColors.deepRed,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'THE MOVEMENT IN NUMBERS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 40,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildStat(_statInvested, 'INVESTED IN CHANGE'),
              _buildStat(_statChangemakers, 'CHANGEMAKERS BUILDING'),
              _buildStat(_statProjects, 'PROJECTS FUNDED'),
              _buildStat(_statHours, 'HOURS CONTRIBUTED'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepRed, AppColors.charcoal, AppColors.electricBlue],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'READY TO BUILD\nSOMETHING THAT MATTERS?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Join thousands of changemakers building real solutions\nto the problems institutions won\'t fix.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.82),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _HeroButton(
            label: 'CREATE FREE ACCOUNT',
            icon: Icons.arrow_forward_rounded,
            filled: true,
            onPressed: () => Navigator.of(context).pushNamed('/signup'),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/login'),
            child: Text(
              'Already a member? Sign in →',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.4),
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
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.charcoal,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

