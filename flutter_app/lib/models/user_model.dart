class User {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? location;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String availabilityStatus;
  final int profileViews;
  final List<String> skills;
  final int reputationPoints;
  final List<String> badges;
  final String? primaryExpertise;
  final String expertiseLevel;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    this.location,
    this.githubUrl,
    this.linkedinUrl,
    this.websiteUrl,
    this.availabilityStatus = 'available',
    this.profileViews = 0,
    this.skills = const [],
    this.reputationPoints = 0,
    this.badges = const [],
    this.primaryExpertise,
    this.expertiseLevel = 'intermediate',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      location: json['location'] as String?,
      githubUrl: json['github_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      availabilityStatus: json['availability_status'] ?? 'available',
      profileViews: json['profile_views'] ?? 0,
      skills: List<String>.from(json['skills'] ?? []),
      reputationPoints: json['reputation_points'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      primaryExpertise: json['primary_expertise'] as String?,
      expertiseLevel: json['expertise_level'] ?? 'intermediate',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (location != null) 'location': location,
      if (githubUrl != null) 'github_url': githubUrl,
      if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
      if (websiteUrl != null) 'website_url': websiteUrl,
      'availability_status': availabilityStatus,
      'profile_views': profileViews,
      'skills': skills,
      'reputation_points': reputationPoints,
      'badges': badges,
      if (primaryExpertise != null) 'primary_expertise': primaryExpertise,
      'expertise_level': expertiseLevel,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
