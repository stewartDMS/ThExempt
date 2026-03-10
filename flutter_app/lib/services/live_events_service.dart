import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/live_event_model.dart';

class LiveEventsService {
  static final _supabase = Supabase.instance.client;

  /// Create or schedule a new live event.
  static Future<LiveEvent> createLiveEvent({
    required String title,
    String? description,
    required String category,
    required String eventType,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String timezone = 'UTC',
    String? meetingLink,
    int maxAttendees = 100,
    bool allowChat = true,
    bool allowReactions = true,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('live_events').insert({
      'host_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'category': category,
      'event_type': eventType,
      if (scheduledStart != null)
        'scheduled_start': scheduledStart.toIso8601String(),
      if (scheduledEnd != null)
        'scheduled_end': scheduledEnd.toIso8601String(),
      'timezone': timezone,
      if (meetingLink != null) 'meeting_link': meetingLink,
      'max_attendees': maxAttendees,
      'allow_chat': allowChat,
      'allow_reactions': allowReactions,
    }).select('*, profiles!host_id(name, avatar_url)').single();

    return LiveEvent.fromJson(response);
  }

  /// List live events with optional filters.
  static Future<List<LiveEvent>> getLiveEvents({
    String? status,
    String? category,
    String? hostId,
  }) async {
    var query = _supabase
        .from('live_events')
        .select('*, profiles!host_id(name, avatar_url)');

    if (status == 'live') {
      query = query.eq('is_live', true);
    } else if (status == 'upcoming') {
      query = query.eq('is_live', false).filter('ended_at', 'is', null);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    if (hostId != null) {
      query = query.eq('host_id', hostId);
    }

    final response =
        await query.order('scheduled_start', ascending: false);

    return response
        .map((j) => LiveEvent.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Get a single live event by ID.
  static Future<LiveEvent> getLiveEvent(String id) async {
    final response = await _supabase
        .from('live_events')
        .select('*, profiles!host_id(name, avatar_url)')
        .eq('id', id)
        .single();

    return LiveEvent.fromJson(response);
  }

  /// Start a live stream (host only).
  static Future<LiveEvent> goLive(String id, {String? streamUrl}) async {
    final response = await _supabase
        .from('live_events')
        .update({
          'is_live': true,
          'started_at': DateTime.now().toIso8601String(),
          if (streamUrl != null) 'stream_url': streamUrl,
        })
        .eq('id', id)
        .select('*, profiles!host_id(name, avatar_url)')
        .single();

    return LiveEvent.fromJson(response);
  }

  /// End a live stream (host only).
  static Future<LiveEvent> endStream(String id, {String? recordingUrl}) async {
    final response = await _supabase
        .from('live_events')
        .update({
          'is_live': false,
          'ended_at': DateTime.now().toIso8601String(),
          if (recordingUrl != null) 'recording_url': recordingUrl,
        })
        .eq('id', id)
        .select('*, profiles!host_id(name, avatar_url)')
        .single();

    return LiveEvent.fromJson(response);
  }

  /// RSVP to an event.
  static Future<void> rsvpToEvent(String id, String status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('event_rsvps').upsert({
      'event_id': id,
      'user_id': userId,
      'status': status,
    });
  }

  /// Remove an RSVP.
  static Future<void> removeRsvp(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('event_rsvps')
        .delete()
        .eq('event_id', id)
        .eq('user_id', userId);
  }

  /// Get chat messages for an event.
  static Future<List<ChatMessage>> getChatMessages(String id) async {
    final response = await _supabase
        .from('event_chat_messages')
        .select('*, profiles!user_id(name, avatar_url)')
        .eq('event_id', id)
        .order('created_at');

    return response
        .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Send a chat message.
  static Future<ChatMessage> sendChatMessage(String id, String message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('event_chat_messages').insert({
      'event_id': id,
      'user_id': userId,
      'message': message,
    }).select('*, profiles!user_id(name, avatar_url)').single();

    return ChatMessage.fromJson(response);
  }

  /// Send a live reaction.
  static Future<void> sendReaction(String id, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('event_reactions').insert({
      'event_id': id,
      'user_id': userId,
      'reaction_type': reactionType,
    });
  }

  /// Get the current viewer count for an event.
  static Future<int> getViewerCount(String id) async {
    final response = await _supabase
        .from('live_events')
        .select('viewers_count')
        .eq('id', id)
        .single();

    return (response['viewers_count'] as num?)?.toInt() ?? 0;
  }
}

