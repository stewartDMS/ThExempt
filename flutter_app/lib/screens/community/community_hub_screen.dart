import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../models/live_event_model.dart';
import '../../services/discussions_service.dart';
import '../../services/live_events_service.dart';
import '../../widgets/discussion_card.dart';
import '../../widgets/live_event_card.dart';
import 'category_discussions_screen.dart';
import 'create_discussion_screen.dart';
import 'my_discussions_screen.dart';
import '../live_events/events_home_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  List<LiveEvent> _liveNow = [];
  List<Discussion> _trending = [];
  bool _loading = true;

  static const _categoryColors = {
    'world_problems': Color(0xFF10B981),
    'ideas': Color(0xFFF59E0B),
    'learning': Color(0xFF3B82F6),
    'live_events': Color(0xFFEF4444),
    'networking': Color(0xFF8B5CF6),
    'feedback': Color(0xFFEC4899),
    'general': Color(0xFF6B7280),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        LiveEventsService.getLiveEvents(status: 'live'),
        DiscussionsService.getDiscussions(sort: 'trending'),
      ]);
      if (mounted) {
        setState(() {
          _liveNow = results[0] as List<LiveEvent>;
          _trending = results[1] as List<Discussion>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Discussions',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyDiscussionsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.live_tv),
            tooltip: 'Live Events',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventsHomeScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Live Now section
                  if (_liveNow.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 10, color: Colors.red),
                            const SizedBox(width: 6),
                            const Text('Live Now',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EventsHomeScreen()),
                              ),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _liveNow.length,
                          itemBuilder: (_, i) => SizedBox(
                            width: 280,
                            child: LiveEventCard(event: _liveNow[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Categories grid
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Categories',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final cat = DiscussionCategory.values[index];
                          final color = _categoryColors[cat.value] ?? const Color(0xFF6B7280);
                          return _CategoryTile(
                            category: cat,
                            color: color,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CategoryDiscussionsScreen(category: cat),
                            )),
                          );
                        },
                        childCount: DiscussionCategory.values.length,
                      ),
                    ),
                  ),
                  // Trending discussions
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Trending',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DiscussionCard(discussion: _trending[index]),
                      childCount: _trending.length,
                    ),
                  ),
                  if (_trending.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No discussions yet. Be the first!',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateDiscussionScreen()),
        ),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Discussion'),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final DiscussionCategory category;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract just the emoji + short name
    final parts = category.label.split(' ');
    final emoji = parts.isNotEmpty ? parts[0] : '';
    final name = parts.length > 1 ? parts.sublist(1).join(' ') : category.label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color.withAlpha(220)),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
