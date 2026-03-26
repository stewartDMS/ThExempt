/// Phase 2 — Collaboration Request model
///
/// Represents a request from one user to connect with another
/// or to join a specific project.
class CollaborationRequest {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String recipientId;
  final String? recipientName;
  final String? recipientAvatarUrl;
  final String? projectId;
  final String? projectTitle;
  final CollabRequestType requestType;
  final String? message;
  final CollabRequestStatus status;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollaborationRequest({
    required this.id,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.recipientId,
    this.recipientName,
    this.recipientAvatarUrl,
    this.projectId,
    this.projectTitle,
    required this.requestType,
    this.message,
    required this.status,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollaborationRequest.fromJson(Map<String, dynamic> json) {
    return CollaborationRequest(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String?,
      recipientAvatarUrl: json['recipient_avatar_url'] as String?,
      projectId: json['project_id'] as String?,
      projectTitle: json['project_title'] as String?,
      requestType: CollabRequestType.fromValue(
          json['request_type'] as String? ?? 'connect'),
      message: json['message'] as String?,
      status: CollabRequestStatus.fromValue(
          json['status'] as String? ?? 'pending'),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  CollaborationRequest copyWith({
    CollabRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return CollaborationRequest(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientAvatarUrl: recipientAvatarUrl,
      projectId: projectId,
      projectTitle: projectTitle,
      requestType: requestType,
      message: message,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

enum CollabRequestType {
  connect('connect', 'Connect'),
  joinProject('join_project', 'Join Project');

  const CollabRequestType(this.value, this.label);
  final String value;
  final String label;

  static CollabRequestType fromValue(String value) =>
      CollabRequestType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => CollabRequestType.connect,
      );
}

enum CollabRequestStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined'),
  withdrawn('withdrawn', 'Withdrawn');

  const CollabRequestStatus(this.value, this.label);
  final String value;
  final String label;

  static CollabRequestStatus fromValue(String value) =>
      CollabRequestStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => CollabRequestStatus.pending,
      );
}
