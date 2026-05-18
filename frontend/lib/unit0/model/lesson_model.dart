import 'step_model.dart';

/// Lesson data model
/// Represents a complete lesson with multiple steps
class Lesson {
  final String lessonId;
  final int unitId;
  final int order;
  final String title;
  final String description;
  final List<LessonStep> steps;

  Lesson({
    required this.lessonId,
    required this.unitId,
    required this.order,
    required this.title,
    required this.description,
    required this.steps,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonId: json['lesson_id'] as String,
      unitId: json['unit_id'] as int,
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List)
          .map((stepJson) => LessonStep.fromJson(stepJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'unit_id': unitId,
      'order': order,
      'title': title,
      'description': description,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

