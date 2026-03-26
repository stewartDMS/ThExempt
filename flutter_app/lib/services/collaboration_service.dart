import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collaboration_request_model.dart';

/// Phase 2 — Collaboration Request Service
///
/// Manages the full lifecycle of collaboration requests:
/// send → respond (accept/decline) → withdraw.
class CollaborationService {
  static final _supabase = Supabase.instance.client;

  // ── Send / Withdraw ────────────────────────────────────────────────────────

  /// Sends a collaboration request to [recipientId].
  ///
  /// [requestType] is either 'connect' (user-to-user) or
  /// 'join_project' (user-to-project).  Supply [projectId] for join_project.
  static Future<CollaborationRequest> sendRequest({
    required String recipientId,
    CollabRequestType requestType = CollabRequestType.connect,
    String? projectId,
    String? message,
  }) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('collaboration_requests')
        .insert({
          'sender_id': senderId,
          'recipient_id': recipientId,
          if (projectId != null) 'project_id': projectId,
          'request_type': requestType.value,
          if (message != null && message.isNotEmpty) 'message': message,
        })
        .select()
        .single();

    return CollaborationRequest.fromJson(response as Map<String, dynamic>);
  }

  /// Withdraws an outgoing request by [requestId].
  static Future<void> withdrawRequest(String requestId) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) throw Exception('User not authenticated');

    await _supabase
        .from('collaboration_requests')
        .update({
          'status': CollabRequestStatus.withdrawn.value,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('sender_id', senderId);
  }

  // ── Respond ────────────────────────────────────────────────────────────────

  /// Accepts an incoming request by [requestId].
  static Future<CollaborationRequest> acceptRequest(String requestId) async {
    final recipientId = _supabase.auth.currentUser?.id;
    if (recipientId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('collaboration_requests')
        .update({
          'status': CollabRequestStatus.accepted.value,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('recipient_id', recipientId)
        .select()
        .single();

    return CollaborationRequest.fromJson(response as Map<String, dynamic>);
  }

  /// Declines an incoming request by [requestId].
  static Future<CollaborationRequest> declineRequest(String requestId) async {
    final recipientId = _supabase.auth.currentUser?.id;
    if (recipientId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('collaboration_requests')
        .update({
          'status': CollabRequestStatus.declined.value,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('recipient_id', recipientId)
        .select()
        .single();

    return CollaborationRequest.fromJson(response as Map<String, dynamic>);
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  /// Returns all incoming pending requests for the current user.
  static Future<List<CollaborationRequest>> getIncomingRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('collaboration_requests')
        .select(
          '*, '
          'sender:profiles!collaboration_requests_sender_id_fkey(name, avatar_url), '
          'project:projects(title)',
        )
        .eq('recipient_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final sender = map.remove('sender') as Map<String, dynamic>?;
      final project = map.remove('project') as Map<String, dynamic>?;
      return CollaborationRequest.fromJson({
        ...map,
        'sender_name': sender?['name'],
        'sender_avatar_url': sender?['avatar_url'],
        'project_title': project?['title'],
      });
    }).toList();
  }

  /// Returns all outgoing requests sent by the current user.
  static Future<List<CollaborationRequest>> getOutgoingRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('collaboration_requests')
        .select(
          '*, '
          'recipient:profiles!collaboration_requests_recipient_id_fkey(name, avatar_url), '
          'project:projects(title)',
        )
        .eq('sender_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final recipient = map.remove('recipient') as Map<String, dynamic>?;
      final project = map.remove('project') as Map<String, dynamic>?;
      return CollaborationRequest.fromJson({
        ...map,
        'recipient_name': recipient?['name'],
        'recipient_avatar_url': recipient?['avatar_url'],
        'project_title': project?['title'],
      });
    }).toList();
  }

  /// Returns the current request status between the signed-in user and
  /// [otherUserId] (and optionally [projectId]).  Returns null if none.
  static Future<CollaborationRequest?> getRequestStatus({
    required String otherUserId,
    String? projectId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    // Check: current user sent to otherUser
    var queryA = _supabase
        .from('collaboration_requests')
        .select()
        .eq('sender_id', userId)
        .eq('recipient_id', otherUserId);

    if (projectId != null) queryA = queryA.eq('project_id', projectId);

    final responseA =
        await queryA.order('created_at', ascending: false).limit(1);

    if ((responseA as List).isNotEmpty) {
      return CollaborationRequest.fromJson(
          responseA.first as Map<String, dynamic>);
    }

    // Check: otherUser sent to current user
    var queryB = _supabase
        .from('collaboration_requests')
        .select()
        .eq('sender_id', otherUserId)
        .eq('recipient_id', userId);

    if (projectId != null) queryB = queryB.eq('project_id', projectId);

    final responseB =
        await queryB.order('created_at', ascending: false).limit(1);

    if ((responseB as List).isNotEmpty) {
      return CollaborationRequest.fromJson(
          responseB.first as Map<String, dynamic>);
    }

    return null;
  }

  /// Returns count of unread (pending) incoming requests.
  static Future<int> getPendingIncomingCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final result = await _supabase
        .from('collaboration_requests')
        .select('id')
        .eq('recipient_id', userId)
        .eq('status', 'pending')
        .count(CountOption.exact);

    return result.count ?? 0;
  }
}
