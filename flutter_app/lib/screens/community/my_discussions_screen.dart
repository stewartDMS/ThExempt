import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/common/discussion_feed_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kDivider       = Color(0xFF2C2C2F);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class MyDiscussionsScreen extends StatefulWidget {
  const MyDiscussionsScreen({super.key});

  @override
  State<MyDiscussionsScreen> createState() => _MyDiscussionsScreenState();
}

class _MyDiscussionsScreenState extends State<MyDiscussionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Discussion> _myDiscussions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadDiscussions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscussions() async {
    setState(() => _loading = true);
    try {
      final discussions =
          await DiscussionsService.getDiscussions(sort: 'recent');
      if (mounted) {
        setState(() {
          _myDiscussions = discussions;
          _loading       = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Discussions',
          style: TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightCyan,
          labelColor: AppColors.brightCyan,
          unselectedLabelColor: _kTextSecondary,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'My Posts')],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.brightCyan))
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadDiscussions,
                  color: AppColors.brightCyan,
                  backgroundColor: _kCardBg,
                  child: _myDiscussions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.electricBlue
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.electricBlue
                                          .withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.forum_outlined,
                                    size: 36,
                                    color: AppColors.brightCyan),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No discussions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your posts will appear here',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _kTextSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.only(
                              bottom: AppSpacing.bottomNavPadding),
                          itemCount: _myDiscussions.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: _kDivider),
                          itemBuilder: (_, i) => DiscussionFeedCard(
                              discussion: _myDiscussions[i]),
                        ),
                ),
              ],
            ),
    );
  }
}
