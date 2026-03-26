import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/common/discussion_feed_card.dart';
import '../../screens/community/discussion_pipeline_panel.dart';

class CategoryDiscussionsScreen extends StatefulWidget {
  final String category;

  const CategoryDiscussionsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryDiscussionsScreen> createState() =>
      _CategoryDiscussionsScreenState();
}

class _CategoryDiscussionsScreenState extends State<CategoryDiscussionsScreen> {
  List<Discussion> _discussions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  String _selectedSort = 'recent';
  String _search = '';
  String? _selectedStage; // null = all stages
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDiscussions(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadDiscussions();
      }
    }
  }

  Future<void> _loadDiscussions({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var result = await DiscussionsService.getDiscussions(
        category: widget.category,
        sort: _selectedSort,
        search: _search.isEmpty ? null : _search,
        limit: 20,
        offset: reset ? 0 : _discussions.length,
      );

      // Client-side stage filter (server-side filtering can be added later)
      if (_selectedStage != null) {
        result = result
            .where((d) => d.stage.value == _selectedStage)
            .toList();
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _discussions = result;
          } else {
            _discussions.addAll(result);
          }
          _hasMore = result.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading discussions: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _search = value);
                    _loadDiscussions(reset: true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search discussions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              // Sort options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Sort: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Recent'),
                        selected: _selectedSort == 'recent',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'recent');
                            _loadDiscussions(reset: true);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Popular'),
                        selected: _selectedSort == 'popular',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'popular');
                            _loadDiscussions(reset: true);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Trending'),
                        selected: _selectedSort == 'trending',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'trending');
                            _loadDiscussions(reset: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Stage filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Stage: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedStage == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStage = null);
                            _loadDiscussions(reset: true);
                          }
                        },
                      ),
                      ...DiscussionStage.values.map((stage) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(stage.label),
                            selected: _selectedStage == stage.value,
                            onSelected: (selected) {
                              setState(() => _selectedStage = selected ? stage.value : null);
                              _loadDiscussions(reset: true);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading discussions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDiscussions(reset: true),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _discussions.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (_discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No discussions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Be the first to start a discussion!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDiscussions(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _discussions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _discussions.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final discussion = _discussions[index];
          return DiscussionFeedCard(
            discussion: discussion,
          );
        },
      ),
    );
  }
}
