import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discussion_resource_model.dart';

/// Phase 1 — Resource library within discussions
///
/// Wraps the discussion_resources table via the Supabase client.
class DiscussionResourcesService {
  static final _supabase = Supabase.instance.client;

  static const String _select =
      '*, profiles:uploaded_by(id, username, avatar_url)';

  // ── List ───────────────────────────────────────────────────────────────

  /// Returns all resources for [discussionId].
  /// Optional [type] filters by resource_type.
  /// [featuredOnly] limits to is_featured = true.
  static Future<List<DiscussionResource>> getResources(
    String discussionId, {
    String? type,
    bool featuredOnly = false,
  }) async {
    var query = _supabase
        .from('discussion_resources')
        .select(_select)
        .eq('discussion_id', discussionId);

    if (type != null)    query = query.eq('resource_type', type);
    if (featuredOnly)    query = query.eq('is_featured', true);

    final response = await query
        .order('is_featured', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => DiscussionResource.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Add ────────────────────────────────────────────────────────────────

  /// Adds a resource (link, document, video, image, or dataset) to a discussion.
  static Future<DiscussionResource> addResource({
    required String discussionId,
    required String resourceType,
    required String title,
    String? description,
    String? url,
    String? fileName,
    int? fileSize,
    String? mimeType,
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('discussion_resources')
        .insert({
          'discussion_id': discussionId,
          'uploaded_by': userId,
          'resource_type': resourceType,
          'title': title,
          if (description != null) 'description': description,
          if (url != null) 'url': url,
          if (fileName != null) 'file_name': fileName,
          if (fileSize != null) 'file_size': fileSize,
          if (mimeType != null) 'mime_type': mimeType,
          'tags': tags,
          'is_featured': isFeatured,
        })
        .select(_select)
        .single();

    return DiscussionResource.fromJson(response as Map<String, dynamic>);
  }

  // ── Update ─────────────────────────────────────────────────────────────

  /// Updates mutable fields of a resource owned by the signed-in user.
  static Future<DiscussionResource> updateResource(
    String resourceId, {
    String? title,
    String? description,
    List<String>? tags,
    bool? isFeatured,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final fields = <String, dynamic>{};
    if (title       != null) fields['title']       = title;
    if (description != null) fields['description'] = description;
    if (tags        != null) fields['tags']        = tags;
    if (isFeatured  != null) fields['is_featured'] = isFeatured;

    if (fields.isEmpty) throw ArgumentError('No fields provided to update');

    final response = await _supabase
        .from('discussion_resources')
        .update(fields)
        .eq('id', resourceId)
        .eq('uploaded_by', userId)
        .select(_select)
        .single();

    return DiscussionResource.fromJson(response as Map<String, dynamic>);
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Deletes a resource owned by the signed-in user.
  static Future<void> deleteResource(String resourceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('discussion_resources')
        .delete()
        .eq('id', resourceId)
        .eq('uploaded_by', userId);
  }

  // ── Pipeline helpers ───────────────────────────────────────────────────

  /// Advances the pipeline stage of a discussion (owner only).
  /// [stage] must be one of: problem, solution, project_proposal, project_linked.
  static Future<void> advancePipelineStage(
    String discussionId,
    String stage,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('discussions')
        .update({'stage': stage})
        .eq('id', discussionId)
        .eq('user_id', userId);
  }

  /// Casts or updates a vote (+1 upvote / -1 downvote) on a discussion.
  static Future<void> castVote(String discussionId, int value) async {
    if (value != 1 && value != -1) {
      throw ArgumentError('Vote value must be 1 (upvote) or -1 (downvote), got $value');
    }
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('discussion_votes').upsert(
      {'discussion_id': discussionId, 'user_id': userId, 'value': value},
      onConflict: 'discussion_id,user_id',
    );
  }

  /// Retracts the signed-in user's vote on a discussion.
  static Future<void> retractVote(String discussionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('discussion_votes')
        .delete()
        .eq('discussion_id', discussionId)
        .eq('user_id', userId);
  }

  /// Links a discussion to a project and sets stage to 'project_linked'.
  static Future<void> linkProject(
    String discussionId,
    String projectId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('discussions')
        .update({
          'stage': 'project_linked',
          'linked_project_id': projectId,
        })
        .eq('id', discussionId)
        .eq('user_id', userId);
  }
}

