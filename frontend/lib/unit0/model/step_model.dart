/// Step data model
/// Represents a single step within a lesson
class LessonStep {
  final String stepType;
  final Map<String, dynamic> content;

  LessonStep({
    required this.stepType,
    required this.content,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      stepType: json['step_type'] as String,
      content: json['content'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_type': stepType,
      'content': content,
    };
  }
}

/// Step type constants
class StepType {
  static const String introduction = 'introduction';
  static const String practice = 'practice';
  static const String quiz = 'quiz';
  static const String completion = 'completion';
}

