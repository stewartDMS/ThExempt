import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discussion_model.dart';

class DiscussionsService {
  static final _supabase = Supabase.instance.client;

  static const String _discussionSelect = '''
    *,
    profiles:author_id (
      id,
      username,
      avatar_url
    ),
    discussion_media (
      id,
      media_type,
      file_url,
      thumbnail_url,
      file_name,
      file_size,
      width,
      height,
      duration_seconds,
      display_order
    )
  ''';

  static Future<Discussion> createDiscussion({
    required String category,
    required String title,
    required String content,
    List<String>? tags,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('discussions').insert({
      'author_id': userId,
      'category': category,
      'title': title,
      'content': content,
      'tags': tags ?? [],
      if (imageUrl != null) 'image_url': imageUrl,
    }).select(_discussionSelect).single();

    return Discussion.fromJson(response);
  }

  static Future<List<Discussion>> getDiscussions({
    String? category,
    String? sort = 'recent',
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('discussions')
          .select(_discussionSelect);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,content.ilike.%$search%');
      }

      final response = await query;
      
      var discussions = (response as List)
          .map((json) => Discussion.fromJson(json))
          .toList();

      // Sort in memory
      switch (sort) {
        case 'popular':
          discussions.sort((a, b) => b.likesCount.compareTo(a.likesCount));
          break;
        case 'trending':
          discussions.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
          break;
        case 'recent':
        default:
          discussions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Pagination
      final start = offset;
      final end = offset + limit;
      
      if (start >= discussions.length) return [];
      
      return discussions.sublist(
        start,
        end > discussions.length ? discussions.length : end,
      );
      
    } catch (e) {
      print('Error fetching discussions: $e');
      rethrow;
    }
  }

  static Future<Discussion> getDiscussion(String id) async {
    final response = await _supabase
        .from('discussions')
        .select(_discussionSelect)
        .eq('id', id)
        .single();

    return Discussion.fromJson(response);
  }

  static Future<DiscussionReply> addReply({
    required String discussionId,
    required String content,
    String? parentReplyId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('discussion_replies').insert({
      'discussion_id': discussionId,
      'author_id': userId,
      'content': content,
      'parent_reply_id': parentReplyId,
    }).select().single();

    return DiscussionReply.fromJson(response);
  }

  static Future<List<DiscussionReply>> getReplies(String discussionId) async {
    final response = await _supabase
        .from('discussion_replies')
        .select('''
          *,
          profiles:author_id (
            username,
            avatar_url
          )
        ''')
        .eq('discussion_id', discussionId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => DiscussionReply.fromJson(json))
        .toList();
  }

  static Future<void> likeDiscussion(String discussionId,
      {String? replyId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

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

  static Future<void> unlikeDiscussion(String discussionId,
      {String? replyId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

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

  static Future<void> deleteDiscussion(String discussionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership
    final discussion = await _supabase
        .from('discussions')
        .select('author_id')
        .eq('id', discussionId)
        .single();

    if (discussion['author_id'] != userId) {
      throw Exception('Not authorized to delete this discussion');
    }

    // Delete associated reply likes
    final replies = await _supabase
        .from('discussion_replies')
        .select('id')
        .eq('discussion_id', discussionId);

    if (replies.isNotEmpty) {
      for (final reply in replies) {
        await _supabase
            .from('discussion_reply_likes')
            .delete()
            .eq('reply_id', reply['id']);
      }
    }

    // Delete discussion likes
    await _supabase
        .from('discussion_likes')
        .delete()
        .eq('discussion_id', discussionId);

    // Delete replies
    await _supabase
        .from('discussion_replies')
        .delete()
        .eq('discussion_id', discussionId);

    // Delete media
    await _supabase
        .from('discussion_media')
        .delete()
        .eq('discussion_id', discussionId);

    // Delete discussion
    await _supabase.from('discussions').delete().eq('id', discussionId);
  }
}
