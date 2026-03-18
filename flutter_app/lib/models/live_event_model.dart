class LiveEvent {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String title;
  final String? description;
  final String category;
  final String eventType;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String timezone;
  final bool isLive;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? streamUrl;
  final String? recordingUrl;
  final String? meetingLink;
  final int maxAttendees;
  final bool allowChat;
  final bool allowReactions;
  final int viewersCount;
  final int peakViewers;
  final int totalViews;
  final int rsvpCount;
  final String? userRsvpStatus;
  final DateTime createdAt;

  LiveEvent({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
    required this.title,
    this.description,
    required this.category,
    required this.eventType,
    this.scheduledStart,
    this.scheduledEnd,
    required this.timezone,
    required this.isLive,
    this.startedAt,
    this.endedAt,
    this.streamUrl,
    this.recordingUrl,
    this.meetingLink,
    required this.maxAttendees,
    required this.allowChat,
    required this.allowReactions,
    required this.viewersCount,
    required this.peakViewers,
    required this.totalViews,
    required this.rsvpCount,
    this.userRsvpStatus,
    required this.createdAt,
  });

  bool get isPast => endedAt != null;
  bool get isUpcoming => !isLive && endedAt == null && scheduledStart != null;

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return LiveEvent(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      hostName: profiles?['username'] ?? 'Unknown',
      hostAvatarUrl: profiles?['avatar_url'] as String?,
      title: json['title'] ?? '',
      description: json['description'] as String?,
      category: json['category'] ?? '',
      eventType: json['event_type'] ?? '',
      scheduledStart: json['scheduled_start'] != null ? DateTime.parse(json['scheduled_start']) : null,
      scheduledEnd: json['scheduled_end'] != null ? DateTime.parse(json['scheduled_end']) : null,
      timezone: json['timezone'] ?? 'UTC',
      isLive: json['is_live'] == true,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      streamUrl: json['stream_url'] as String?,
      recordingUrl: json['recording_url'] as String?,
      meetingLink: json['meeting_link'] as String?,
      maxAttendees: (json['max_attendees'] as num?)?.toInt() ?? 100,
      allowChat: json['allow_chat'] != false,
      allowReactions: json['allow_reactions'] != false,
      viewersCount: (json['viewers_count'] as num?)?.toInt() ?? 0,
      peakViewers: (json['peak_viewers'] as num?)?.toInt() ?? 0,
      totalViews: (json['total_views'] as num?)?.toInt() ?? 0,
      rsvpCount: (json['rsvp_count'] as num?)?.toInt() ?? 0,
      userRsvpStatus: json['user_rsvp_status'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'host_id': hostId,
    'title': title,
    if (description != null) 'description': description,
    'category': category,
    'event_type': eventType,
    if (scheduledStart != null) 'scheduled_start': scheduledStart!.toIso8601String(),
    if (scheduledEnd != null) 'scheduled_end': scheduledEnd!.toIso8601String(),
    'timezone': timezone,
    'is_live': isLive,
    if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
    if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    if (streamUrl != null) 'stream_url': streamUrl,
    if (recordingUrl != null) 'recording_url': recordingUrl,
    if (meetingLink != null) 'meeting_link': meetingLink,
    'max_attendees': maxAttendees,
    'allow_chat': allowChat,
    'allow_reactions': allowReactions,
    'viewers_count': viewersCount,
    'peak_viewers': peakViewers,
    'total_views': totalViews,
    'rsvp_count': rsvpCount,
    'created_at': createdAt.toIso8601String(),
  };

  LiveEvent copyWith({
    bool? isLive,
    int? viewersCount,
    int? rsvpCount,
    String? userRsvpStatus,
    String? recordingUrl,
    String? meetingLink,
  }) {
    return LiveEvent(
      id: id,
      hostId: hostId,
      hostName: hostName,
      hostAvatarUrl: hostAvatarUrl,
      title: title,
      description: description,
      category: category,
      eventType: eventType,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      timezone: timezone,
      isLive: isLive ?? this.isLive,
      startedAt: startedAt,
      endedAt: endedAt,
      streamUrl: streamUrl,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      meetingLink: meetingLink ?? this.meetingLink,
      maxAttendees: maxAttendees,
      allowChat: allowChat,
      allowReactions: allowReactions,
      viewersCount: viewersCount ?? this.viewersCount,
      peakViewers: peakViewers,
      totalViews: totalViews,
      rsvpCount: rsvpCount ?? this.rsvpCount,
      userRsvpStatus: userRsvpStatus ?? this.userRsvpStatus,
      createdAt: createdAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String message;
  final bool isPinned;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.message,
    required this.isPinned,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['username'] ?? 'Unknown',
      userAvatarUrl: profiles?['avatar_url'] as String?,
      message: json['message'] ?? '',
      isPinned: json['is_pinned'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

enum LiveEventType {
  training('training', '🎓 Training Session', 'Expert workshops and courses'),
  ama('ama', '💬 AMA', 'Ask Me Anything sessions'),
  discussion('discussion', '🌍 Discussion', 'Live debates on world problems'),
  pitch('pitch', '🎤 Pitch Session', 'Present ideas live'),
  officeHours('office_hours', '🤝 Office Hours', '1-on-1 mentorship slots');

  const LiveEventType(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static LiveEventType? fromValue(String value) {
    for (final t in LiveEventType.values) {
      if (t.value == value) return t;
    }
    return null;
  }
}
