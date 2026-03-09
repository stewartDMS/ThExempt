import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/discussion_card.dart';

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
      final discussions = await DiscussionsService.getDiscussions(sort: 'recent');
      if (mounted) {
        setState(() {
          _myDiscussions = discussions;
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
        title: const Text('My Discussions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'My Posts')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadDiscussions,
                  child: _myDiscussions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No discussions yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _myDiscussions.length,
                          itemBuilder: (_, i) =>
                              DiscussionCard(discussion: _myDiscussions[i]),
                        ),
                ),
              ],
            ),
    );
  }
}
