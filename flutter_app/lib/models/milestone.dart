import 'task.dart';
import 'project_stage.dart';

class Milestone {
  final String id;
  final String title;
  final String? description;
  final ProjectStage stage;
  final DateTime? startDate;
  final DateTime? completedDate;
  final DateTime? estimatedCompletion;
  final double progress; // 0.0 - 1.0
  final List<Task> tasks;
  final bool isComplete;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.stage,
    this.startDate,
    this.completedDate,
    this.estimatedCompletion,
    required this.progress,
    required this.tasks,
    required this.isComplete,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      stage: ProjectStage.fromString(json['stage'] ?? 'ideation'),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'])
          : null,
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.tryParse(json['estimated_completion'])
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }
}
