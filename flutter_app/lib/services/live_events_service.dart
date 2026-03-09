import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/live_event_model.dart';

class LiveEventsService {
  static const String apiUrl = 'http://localhost:5000/api';

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/live-events'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        if (description != null) 'description': description,
        'category': category,
        'event_type': eventType,
        if (scheduledStart != null) 'scheduled_start': scheduledStart.toIso8601String(),
        if (scheduledEnd != null) 'scheduled_end': scheduledEnd.toIso8601String(),
        'timezone': timezone,
        if (meetingLink != null) 'meeting_link': meetingLink,
        'max_attendees': maxAttendees,
        'allow_chat': allowChat,
        'allow_reactions': allowReactions,
      }),
    );

    if (response.statusCode == 201) {
      return LiveEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create live event: ${response.body}');
  }

  /// List live events with optional filters.
  static Future<List<LiveEvent>> getLiveEvents({
    String? status,
    String? category,
    String? hostId,
  }) async {
    final headers = await _authHeaders();
    final params = {
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (hostId != null) 'host_id': hostId,
    };
    final uri = Uri.parse('$apiUrl/live-events').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => LiveEvent.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load live events');
  }

  /// Get a single live event by ID.
  static Future<LiveEvent> getLiveEvent(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$apiUrl/live-events/$id'), headers: headers);

    if (response.statusCode == 200) {
      return LiveEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load live event');
  }

  /// Start a live stream (host only).
  static Future<LiveEvent> goLive(String id, {String? streamUrl}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/live-events/$id/go-live'),
      headers: headers,
      body: jsonEncode({if (streamUrl != null) 'stream_url': streamUrl}),
    );

    if (response.statusCode == 200) {
      return LiveEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to go live');
  }

  /// End a live stream (host only).
  static Future<LiveEvent> endStream(String id, {String? recordingUrl}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/live-events/$id/end'),
      headers: headers,
      body: jsonEncode({if (recordingUrl != null) 'recording_url': recordingUrl}),
    );

    if (response.statusCode == 200) {
      return LiveEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to end stream');
  }

  /// RSVP to an event.
  static Future<void> rsvpToEvent(String id, String status) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/live-events/$id/rsvp'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to RSVP');
    }
  }

  /// Remove an RSVP.
  static Future<void> removeRsvp(String id) async {
    final headers = await _authHeaders();
    final request = http.Request('DELETE', Uri.parse('$apiUrl/live-events/$id/rsvp'));
    request.headers.addAll(headers);
    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to remove RSVP');
    }
  }

  /// Get chat messages for an event.
  static Future<List<ChatMessage>> getChatMessages(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$apiUrl/live-events/$id/chat'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => ChatMessage.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load chat');
  }

  /// Send a chat message.
  static Future<ChatMessage> sendChatMessage(String id, String message) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/live-events/$id/chat'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 201) {
      return ChatMessage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to send message');
  }

  /// Send a live reaction.
  static Future<void> sendReaction(String id, String reactionType) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$apiUrl/live-events/$id/reaction'),
      headers: headers,
      body: jsonEncode({'reaction_type': reactionType}),
    );
  }

  /// Get the current viewer count for an event.
  static Future<int> getViewerCount(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$apiUrl/live-events/$id/viewers'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['viewers_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
