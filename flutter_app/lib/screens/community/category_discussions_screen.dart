import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/common/discussion_feed_card.dart';
import '../../screens/community/discussion_pipeline_panel.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kInputFill     = Color(0xFF252528);
const _kBorder        = Color(0xFF3A3A3C);
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

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

class _CategoryDiscussionsScreenState
    extends State<CategoryDiscussionsScreen> {
  List<Discussion> _discussions = [];
  bool _isLoading  = false;
  bool _hasMore    = true;
  String? _error;
  String _selectedSort  = 'recent';
  String _search        = '';
  String? _selectedStage;
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
      if (!_isLoading && _hasMore) _loadDiscussions();
    }
  }

  Future<void> _loadDiscussions({bool reset = false}) async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      var result = await DiscussionsService.getDiscussions(
        category: widget.category,
        sort: _selectedSort,
        search: _search.isEmpty ? null : _search,
        limit: 20,
        offset: reset ? 0 : _discussions.length,
      );
      if (_selectedStage != null) {
        result = result
            .where((d) => d.stage.value == _selectedStage)
            .toList();
      }
      if (mounted) {
        setState(() {
          if (reset) _discussions = result; else _discussions.addAll(result);
          _hasMore   = result.length == 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  void _setSort(String sort) {
    if (_selectedSort == sort) return;
    setState(() => _selectedSort = sort);
    _loadDiscussions(reset: true);
  }

  void _setStage(String? stage) {
    if (_selectedStage == stage) return;
    setState(() => _selectedStage = stage);
    _loadDiscussions(reset: true);
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
        title: Text(
          widget.category,
          style: const TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(136),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                  onChanged: (v) {
                    setState(() => _search = v);
                    _loadDiscussions(reset: true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search discussions…',
                    hintStyle: TextStyle(
                        color: _kTextSecondary.withOpacity(0.5),
                        fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: _kTextSecondary, size: 20),
                    filled: true,
                    fillColor: _kInputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.brightCyan, width: 1.5),
                    ),
                  ),
                ),
              ),
              // Sort pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(label: '🕐 Recent', value: 'recent',
                          selected: _selectedSort == 'recent',
                          onTap: () => _setSort('recent')),
                      const SizedBox(width: 8),
                      _SortChip(label: '👥 Popular', value: 'popular',
                          selected: _selectedSort == 'popular',
                          onTap: () => _setSort('popular')),
                      const SizedBox(width: 8),
                      _SortChip(label: '🔥 Trending', value: 'trending',
                          selected: _selectedSort == 'trending',
                          onTap: () => _setSort('trending')),
                    ],
                  ),
                ),
              ),
              // Stage pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                          label: 'All Stages',
                          value: null,
                          selected: _selectedStage == null,
                          onTap: () => _setStage(null)),
                      ...DiscussionStage.values.map((stage) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _SortChip(
                              label: stage.label,
                              value: stage.value,
                              selected: _selectedStage == stage.value,
                              onTap: () => _setStage(stage.value),
                            ),
                          )),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.deepRed),
              const SizedBox(height: 16),
              const Text(
                'Error loading discussions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary),
              ),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _kTextSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _loadDiscussions(reset: true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _discussions.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brightCyan));
    }

    if (_discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 56, color: _kTextSecondary),
            const SizedBox(height: 16),
            const Text(
              'No discussions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to start a discussion!',
              style: TextStyle(color: _kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDiscussions(reset: true),
      color: AppColors.brightCyan,
      backgroundColor: _kCardBg,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: _discussions.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _kDivider),
        itemBuilder: (context, index) {
          if (index == _discussions.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.brightCyan),
              ),
            );
          }
          return DiscussionFeedCard(discussion: _discussions[index]);
        },
      ),
    );
  }
}

// ── Sort/stage pill chip ───────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue.withOpacity(0.2)
              : _kCardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.brightCyan.withOpacity(0.6)
                : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.brightCyan : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}
