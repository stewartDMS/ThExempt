import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discussion_model.dart';

class DiscussionsService {
  static final _supabase = Supabase.instance.client;

  /// Create a new discussion thread.
  static Future<Discussion> createDiscussion({
    required String category,
    required String title,
    required String content,
    List<String>? tags,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('discussions').insert({
      'author_id': userId,
      'category': category,
      'title': title,
      'content': content,
      'tags': tags ?? [],
      if (imageUrl != null) 'image_url': imageUrl,
    }).select('*, profiles!author_id(name, avatar_url)').single();

    return Discussion.fromJson(response);
  }

  /// List discussions with optional filters.
  static Future<List<Discussion>> getDiscussions({
    String? category,
    String? search,
    String sort = 'recent',
    int page = 1,
  }) async {
    var query = _supabase
        .from('discussions')
        .select('*, profiles!author_id(name, avatar_url)');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (search != null && search.isNotEmpty) {
      // Escape special LIKE characters to prevent query manipulation
      final sanitized = search.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
      query = query.or('title.ilike.%$sanitized%,content.ilike.%$sanitized%');
    }

    final from = (page - 1) * 20;
    final to = from + 19;

    final response = sort == 'trending'
        ? await query
            .order('likes_count', ascending: false)
            .range(from, to)
        : await query
            .order('created_at', ascending: false)
            .range(from, to);

    return response
        .map((j) => Discussion.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Get a single discussion by ID.
  static Future<Discussion> getDiscussion(String id) async {
    final response = await _supabase
        .from('discussions')
        .select('*, profiles!author_id(name, avatar_url)')
        .eq('id', id)
        .single();

    return Discussion.fromJson(response);
  }

  /// Add a reply to a discussion.
  static Future<DiscussionReply> addReply({
    required String discussionId,
    required String content,
    String? parentReplyId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('discussion_replies').insert({
      'discussion_id': discussionId,
      'author_id': userId,
      'content': content,
      if (parentReplyId != null) 'parent_reply_id': parentReplyId,
    }).select('*, profiles!author_id(name, avatar_url)').single();

    return DiscussionReply.fromJson(response);
  }

  /// Get nested replies for a discussion.
  static Future<List<DiscussionReply>> getReplies(String discussionId) async {
    final response = await _supabase
        .from('discussion_replies')
        .select('*, profiles!author_id(name, avatar_url)')
        .eq('discussion_id', discussionId)
        .order('created_at');

    return response
        .map((j) => DiscussionReply.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Like a discussion post (or reply if [replyId] is provided).
  static Future<void> likeDiscussion(String discussionId,
      {String? replyId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    if (replyId != null) {
      await _supabase.from('discussion_reply_likes').insert({
        'reply_id': replyId,
        'user_id': userId,
      });
    } else {
      await _supabase.from('discussion_likes').insert({
        'discussion_id': discussionId,
        'user_id': userId,
      });
    }
  }

  /// Remove a like from a discussion (or reply if [replyId] is provided).
  static Future<void> unlikeDiscussion(String discussionId,
      {String? replyId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    if (replyId != null) {
      await _supabase
          .from('discussion_reply_likes')
          .delete()
          .eq('reply_id', replyId)
          .eq('user_id', userId);
    } else {
      await _supabase
          .from('discussion_likes')
          .delete()
          .eq('discussion_id', discussionId)
          .eq('user_id', userId);
    }
  }
}

