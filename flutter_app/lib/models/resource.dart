enum ResourceType { document, link, video }

class Resource {
  final String id;
  final ResourceType type;
  final String title;
  final String? url;
  final String? fileUrl;
  final DateTime uploadedDate;
  final String uploadedBy;
  final String? uploadedByName;
  final String? fileSize;
  final String? fileType;

  Resource({
    required this.id,
    required this.type,
    required this.title,
    this.url,
    this.fileUrl,
    required this.uploadedDate,
    required this.uploadedBy,
    this.uploadedByName,
    this.fileSize,
    this.fileType,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id']?.toString() ?? '',
      type: ResourceType.values.firstWhere(
        (t) => t.name == (json['type'] ?? 'link'),
        orElse: () => ResourceType.link,
      ),
      title: json['title'] ?? '',
      url: json['url'] as String?,
      fileUrl: json['file_url'] as String?,
      uploadedDate: json['uploaded_date'] != null
          ? DateTime.parse(json['uploaded_date'])
          : DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString() ?? '',
      uploadedByName: json['uploaded_by_name'] as String?,
      fileSize: json['file_size'] as String?,
      fileType: json['file_type'] as String?,
    );
  }
}
