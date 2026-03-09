import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/discussion_card.dart';
import 'create_discussion_screen.dart';

class CategoryDiscussionsScreen extends StatefulWidget {
  final DiscussionCategory category;

  const CategoryDiscussionsScreen({super.key, required this.category});

  @override
  State<CategoryDiscussionsScreen> createState() => _CategoryDiscussionsScreenState();
}

class _CategoryDiscussionsScreenState extends State<CategoryDiscussionsScreen> {
  List<Discussion> _discussions = [];
  bool _loading = true;
  String _sort = 'recent';
  String _search = '';
  final _searchController = TextEditingController();
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadDiscussions({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
        _discussions = [];
      });
    }
    try {
      final result = await DiscussionsService.getDiscussions(
        category: widget.category.value,
        search: _search.isEmpty ? null : _search,
        sort: _sort,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _discussions = reset ? result : [..._discussions, ...result];
          _hasMore = result.length >= 20;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() { _loadingMore = true; _page++; });
    await _loadDiscussions(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                          _loadDiscussions();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) {
                setState(() => _search = v);
                if (v.isEmpty || v.length >= 2) _loadDiscussions();
              },
            ),
          ),
          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(widget.category.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                _SortChip(label: 'Recent', value: 'recent', current: _sort, onTap: _setSort),
                const SizedBox(width: 6),
                _SortChip(label: 'Popular', value: 'popular', current: _sort, onTap: _setSort),
                const SizedBox(width: 6),
                _SortChip(label: 'Trending', value: 'trending', current: _sort, onTap: _setSort),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _discussions.isEmpty
                    ? _EmptyState(
                        categoryLabel: widget.category.label,
                        onCreate: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) => CreateDiscussionScreen(
                                    initialCategory: widget.category.value)))
                            .then((_) => _loadDiscussions()),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadDiscussions(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: _discussions.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _discussions.length) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            return DiscussionCard(discussion: _discussions[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) =>
                    CreateDiscussionScreen(initialCategory: widget.category.value)))
            .then((_) => _loadDiscussions()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _setSort(String sort) {
    setState(() => _sort = sort);
    _loadDiscussions();
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String categoryLabel;
  final VoidCallback onCreate;

  const _EmptyState({required this.categoryLabel, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No discussions in $categoryLabel yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Be the first to start a conversation!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Start a Discussion'),
          ),
        ],
      ),
    );
  }
}
