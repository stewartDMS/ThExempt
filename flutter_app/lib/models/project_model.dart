class Project {
  final String id;
  final String title;
  final String description;
  final String company;
  final String duration;
  final String budget;
  final List<String> skills;
  final String postedBy;
  final DateTime createdAt;
  final int applicantsCount;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.duration,
    required this.budget,
    required this.skills,
    required this.postedBy,
    required this.createdAt,
    required this.applicantsCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      company: json['company'] ?? '',
      duration: json['duration'] ?? '',
      budget: json['budget'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      postedBy: json['postedBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      applicantsCount: json['applicantsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'company': company,
      'duration': duration,
      'budget': budget,
      'skills': skills,
      'postedBy': postedBy,
      'createdAt': createdAt.toIso8601String(),
      'applicantsCount': applicantsCount,
    };
  }
}
