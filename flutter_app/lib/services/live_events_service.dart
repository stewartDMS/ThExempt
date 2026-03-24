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
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    throw UnsupportedError('live_events table is not available in the current schema.');
  }

  /// List live events with optional filters.
  static Future<List<LiveEvent>> getLiveEvents({
    String? status,
    String? category,
    String? hostId,
  }) async {
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    return [];
  }

  /// Get a single live event by ID.
  static Future<LiveEvent> getLiveEvent(String id) async {
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    throw UnsupportedError('live_events table is not available in the current schema.');
  }

  /// Start a live stream (host only).
  static Future<LiveEvent> goLive(String id, {String? streamUrl}) async {
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    throw UnsupportedError('live_events table is not available in the current schema.');
  }

  /// End a live stream (host only).
  static Future<LiveEvent> endStream(String id, {String? recordingUrl}) async {
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    throw UnsupportedError('live_events table is not available in the current schema.');
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
        .select('*, profiles!user_id(username, avatar_url)')
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
    }).select('*, profiles!user_id(username, avatar_url)').single();

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
    // TODO: The live_events table does not exist in the current schema.
    // Create the live_events table before enabling this functionality.
    return 0;
  }
}

