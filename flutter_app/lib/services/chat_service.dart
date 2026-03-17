import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['name'] ?? json['user_name'] ?? 'Unknown',
      userAvatar: profiles?['avatar_url'] as String?,
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class ChatService {
  static final _supabase = Supabase.instance.client;

  /// Load the most recent [limit] messages for a project.
  static Future<List<ChatMessage>> getMessages(
    String projectId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('project_messages')
          .select('*, profiles!user_id(name, avatar_url)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Send a chat message.
  static Future<void> sendMessage(
      String projectId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('project_messages').insert({
      'project_id': projectId,
      'user_id': userId,
      'content': content,
    });
  }

  /// Subscribe to new messages for a project in real-time.
  static RealtimeChannel subscribeToMessages(
    String projectId,
    void Function(ChatMessage) onMessage,
  ) {
    return _supabase
        .channel('project_messages_$projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'project_messages',
          callback: (payload) {
            try {
              final record = payload.newRecord;
              if (record['project_id']?.toString() == projectId) {
                final msg = ChatMessage.fromJson(record);
                onMessage(msg);
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  static void unsubscribe(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }
}
