import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../services/discussions_service.dart';
import '../../widgets/reply_card.dart';
import '../../widgets/common/media_gallery_widget.dart';
import '../../utils/time_ago.dart';
import '../../theme/app_colors.dart';
import '../projects/create_project_screen.dart';
import 'discussion_pipeline_panel.dart';
import 'discussion_resources_panel.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kInputFill     = Color(0xFF252528);
const _kBorder        = Color(0xFF3A3A3C);
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class DiscussionDetailScreen extends StatefulWidget {
  final String discussionId;

  const DiscussionDetailScreen({super.key, required this.discussionId});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen>
    with SingleTickerProviderStateMixin {
  Discussion? _discussion;
  List<DiscussionReply> _replies = [];
  bool _loading = true;
  bool _submittingReply = false;
  final _replyController = TextEditingController();
  DiscussionReply? _replyingTo;
  final _scrollController = ScrollController();
  late final TabController _tabController;

  static const _tabs = ['Discussion', 'Resources', 'Pipeline'];
  static const _pipelineTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        DiscussionsService.getDiscussion(widget.discussionId),
        DiscussionsService.getReplies(widget.discussionId),
      ]);
      if (mounted) {
        setState(() {
          _discussion = results[0] as Discussion;
          _replies = results[1] as List<DiscussionReply>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchProjectFlow() async {
    if (_discussion == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          initialTitle: _discussion!.title,
          initialDescription: _discussion!.content,
          sourceDiscussionId: _discussion!.id,
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_discussion == null) return;
    try {
      if (_discussion!.isLikedByUser) {
        await DiscussionsService.unlikeDiscussion(widget.discussionId);
        setState(() {
          _discussion = _discussion!.copyWith(
            isLikedByUser: false,
            likesCount: _discussion!.likesCount - 1,
          );
        });
      } else {
        await DiscussionsService.likeDiscussion(widget.discussionId);
        setState(() {
          _discussion = _discussion!.copyWith(
            isLikedByUser: true,
            likesCount: _discussion!.likesCount + 1,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleReplyLike(DiscussionReply reply) async {
    try {
      if (reply.isLikedByUser) {
        await DiscussionsService.unlikeDiscussion(widget.discussionId, replyId: reply.id);
      } else {
        await DiscussionsService.likeDiscussion(widget.discussionId, replyId: reply.id);
      }
      // Reload replies to reflect updated like state
      final updatedReplies = await DiscussionsService.getReplies(widget.discussionId);
      if (mounted) setState(() => _replies = updatedReplies);
    } catch (_) {}
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingReply = true);
    try {
      await DiscussionsService.addReply(
        discussionId: widget.discussionId,
        content: text,
        parentReplyId: _replyingTo?.id,
      );
      _replyController.clear();
      setState(() { _replyingTo = null; _submittingReply = false; });
      final updatedReplies = await DiscussionsService.getReplies(widget.discussionId);
      if (mounted) {
        setState(() {
          _replies = updatedReplies;
          _discussion = _discussion?.copyWith(repliesCount: updatedReplies.length);
        });
      }
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _submittingReply = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kTextPrimary),
        title: const Text('Discussion',
            style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (_discussion != null)
            IconButton(
              icon: Icon(
                _discussion!.isLikedByUser ? Icons.favorite : Icons.favorite_outline,
                color: _discussion!.isLikedByUser ? AppColors.deepRed : _kTextSecondary,
              ),
              onPressed: _toggleLike,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brightCyan,
          unselectedLabelColor: _kTextSecondary,
          indicatorColor: AppColors.brightCyan,
          indicatorWeight: 2.5,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brightCyan))
          : _discussion == null
              ? const Center(child: Text('Discussion not found',
                  style: TextStyle(color: _kTextSecondary)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 0: Discussion ─────────────────────────────────
                    Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.brightCyan,
                            backgroundColor: _kCardBg,
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                // Discussion content
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category badge + stage badge
                                      Row(
                                        children: [
                                          _CategoryBadge(category: _discussion!.category),
                                          const SizedBox(width: 8),
                                          PipelineStageBadge(stage: _discussion!.stage),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Title
                                      Text(_discussion!.title,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: _kTextPrimary,
                                              height: 1.3)),
                                      const SizedBox(height: 12),
                                      // Author + time
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundImage: _discussion!.authorAvatarUrl != null
                                                ? NetworkImage(_discussion!.authorAvatarUrl!)
                                                : null,
                                            backgroundColor:
                                                AppColors.electricBlue.withOpacity(0.2),
                                            child: _discussion!.authorAvatarUrl == null
                                                ? Text(
                                                    _discussion!.authorName.isNotEmpty
                                                        ? _discussion!.authorName[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.brightCyan))
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_discussion!.authorName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _kTextPrimary)),
                                          const SizedBox(width: 8),
                                          const Text('·',
                                              style: TextStyle(color: _kTextSecondary)),
                                          const SizedBox(width: 8),
                                          Text(timeAgo(_discussion!.createdAt),
                                              style: const TextStyle(
                                                  color: _kTextSecondary, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Content
                                      Text(_discussion!.content,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.6,
                                              color: _kTextPrimary)),
                                      // Media gallery
                                      if (_discussion!.hasMedia) ...[
                                        const SizedBox(height: 16),
                                        MediaGalleryWidget(media: _discussion!.media),
                                      ],
                                      // Tags
                                      if (_discussion!.tags.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: _discussion!.tags
                                              .map((t) => Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.electricBlue
                                                          .withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(999),
                                                      border: Border.all(
                                                          color: AppColors.electricBlue
                                                              .withOpacity(0.3)),
                                                    ),
                                                    child: Text('#$t',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors.brightCyan,
                                                            fontWeight: FontWeight.w600)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      // Stats row
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _kInputFill,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            _StatItem(
                                              icon: Icons.favorite,
                                              count: _discussion!.likesCount,
                                              active: _discussion!.isLikedByUser,
                                              activeColor: AppColors.deepRed,
                                              onTap: _toggleLike,
                                            ),
                                            const SizedBox(width: 16),
                                            _StatItem(
                                                icon: Icons.chat_bubble_outline,
                                                count: _discussion!.repliesCount),
                                            const SizedBox(width: 16),
                                            _StatItem(
                                                icon: Icons.visibility_outlined,
                                                count: _discussion!.viewsCount),
                                            const SizedBox(width: 16),
                                            _StatItem(
                                              icon: Icons.how_to_vote_outlined,
                                              count: _discussion!.votesCount,
                                              onTap: () => _tabController
                                                  .animateTo(_pipelineTabIndex),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Turn this into a project button
                                      OutlinedButton.icon(
                                        onPressed: _launchProjectFlow,
                                        icon: const Icon(Icons.rocket_launch_outlined,
                                            size: 18, color: AppColors.brightCyan),
                                        label: const Text('Turn this into a project',
                                            style: TextStyle(color: AppColors.brightCyan)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                              color: AppColors.brightCyan.withOpacity(0.5)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24)),
                                          textStyle: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: _kDivider),
                                // Replies header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                  child: Text(
                                    '${_replies.length} ${_replies.length == 1 ? 'Reply' : 'Replies'}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _kTextPrimary),
                                  ),
                                ),
                                // Replies
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: _replies
                                        .map((r) => ReplyCard(
                                              reply: r,
                                              onLike: _toggleReplyLike,
                                              onReply: (r) => setState(() {
                                                _replyingTo = r;
                                              }),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Reply input
                        _ReplyInput(
                          controller: _replyController,
                          replyingTo: _replyingTo,
                          isSubmitting: _submittingReply,
                          onCancelReply: () => setState(() => _replyingTo = null),
                          onSubmit: _submitReply,
                        ),
                      ],
                    ),

                    // ── Tab 1: Resources ──────────────────────────────────
                    SingleChildScrollView(
                      child: DiscussionResourcesPanel(
                        discussionId: _discussion!.id,
                        discussionAuthorId: _discussion!.authorId,
                      ),
                    ),

                    // ── Tab 2: Pipeline ───────────────────────────────────
                    SingleChildScrollView(
                      child: DiscussionPipelinePanel(
                        discussion: _discussion!,
                        onUpdated: (updated) {
                          setState(() => _discussion = updated);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  Color _catColor() {
    switch (category) {
      case 'world_problems':  return const Color(0xFF057642);
      case 'ideas':           return const Color(0xFFF5A623);
      case 'learning':        return const Color(0xFF0A66C2);
      case 'live_events':     return const Color(0xFFCC1016);
      case 'networking':      return const Color(0xFF7B61FF);
      case 'feedback':        return const Color(0xFFE91E8C);
      default:                return AppColors.electricBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = DiscussionCategory.fromValue(category);
    final label = cat?.label ?? category;
    final color = _catColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;
  const _StatItem({
    required this.icon,
    required this.count,
    this.active = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? AppColors.brightCyan)
        : _kTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final DiscussionReply? replyingTo;
  final bool isSubmitting;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  const _ReplyInput({
    required this.controller,
    required this.replyingTo,
    required this.isSubmitting,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: const Border(top: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text('Replying to ${replyingTo!.authorName}',
                      style: const TextStyle(
                          fontSize: 12, color: _kTextSecondary)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.close,
                        size: 14, color: _kTextSecondary),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: replyingTo != null
                        ? 'Reply to ${replyingTo!.authorName}...'
                        : 'Add a reply...',
                    hintStyle: const TextStyle(color: _kTextSecondary),
                    filled: true,
                    fillColor: _kInputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppColors.brightCyan, width: 1.5),
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brightCyan))
                    : const Icon(Icons.send, color: AppColors.brightCyan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
