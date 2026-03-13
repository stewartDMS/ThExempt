import 'package:flutter/material.dart';

enum ProjectStage {
  ideation,
  design,
  development,
  launch,
  scale;

  String get displayName {
    switch (this) {
      case ProjectStage.ideation:
        return 'Ideation';
      case ProjectStage.design:
        return 'Design';
      case ProjectStage.development:
        return 'Development';
      case ProjectStage.launch:
        return 'Launch';
      case ProjectStage.scale:
        return 'Scale';
    }
  }

  String get emoji {
    switch (this) {
      case ProjectStage.ideation:
        return '💡';
      case ProjectStage.design:
        return '🎨';
      case ProjectStage.development:
        return '⚙️';
      case ProjectStage.launch:
        return '🚀';
      case ProjectStage.scale:
        return '📈';
    }
  }

  String get description {
    switch (this) {
      case ProjectStage.ideation:
        return 'Concept & validation phase';
      case ProjectStage.design:
        return 'Planning & wireframing phase';
      case ProjectStage.development:
        return 'Building the product';
      case ProjectStage.launch:
        return 'Go-to-market phase';
      case ProjectStage.scale:
        return 'Growth & optimization';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStage.ideation:
        return const Color(0xFF9C27B0); // Purple
      case ProjectStage.design:
        return const Color(0xFFE91E63); // Pink
      case ProjectStage.development:
        return const Color(0xFF2196F3); // Blue
      case ProjectStage.launch:
        return const Color(0xFFFF9800); // Orange
      case ProjectStage.scale:
        return const Color(0xFF4CAF50); // Green
    }
  }

  List<String> get suggestedSkills {
    switch (this) {
      case ProjectStage.ideation:
        return [
          'Market Research',
          'Business Strategy',
          'UX Research',
          'Product Management',
          'Business Planning',
          'Competitive Analysis',
        ];
      case ProjectStage.design:
        return [
          'UI/UX Design',
          'Product Design',
          'Graphic Design',
          'Branding',
          'Wireframing',
          'Prototyping',
          'Figma',
          'Adobe XD',
        ];
      case ProjectStage.development:
        return [
          'Frontend Development',
          'Backend Development',
          'Mobile Development',
          'DevOps',
          'React',
          'Node.js',
          'Python',
          'Flutter',
          'iOS',
          'Android',
          'Database Design',
          'API Development',
        ];
      case ProjectStage.launch:
        return [
          'Marketing',
          'Digital Marketing',
          'Content Creation',
          'Copywriting',
          'SEO',
          'PR',
          'Growth Hacking',
          'Social Media',
          'Email Marketing',
          'Sales',
        ];
      case ProjectStage.scale:
        return [
          'Analytics',
          'Data Science',
          'Performance Marketing',
          'Growth Marketing',
          'SEO',
          'Sales',
          'Business Development',
          'Customer Success',
          'Product Analytics',
        ];
    }
  }

  static ProjectStage fromString(String value) {
    return ProjectStage.values.firstWhere(
      (stage) => stage.name == value.toLowerCase(),
      orElse: () => ProjectStage.ideation,
    );
  }
}
