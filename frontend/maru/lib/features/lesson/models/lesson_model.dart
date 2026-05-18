import 'step_model.dart';

class LessonModel {
  final String lessonId;
  final int unitId;
  final String unitTitle;
  final int orderNum;
  final String title;
  final String description;
  final int difficultyLevel;
  final int estimatedMinutes;
  final bool isPublished;
  final List<StepModel> steps;

  LessonModel({
    required this.lessonId,
    required this.unitId,
    required this.unitTitle,
    required this.orderNum,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.estimatedMinutes,
    required this.isPublished,
    required this.steps,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    // Backend returns content as { "steps": [...] }
    final contentObj = json['content'] as Map<String, dynamic>? ?? {};
    final stepsList = contentObj['steps'] as List<dynamic>? ?? [];

    return LessonModel(
      lessonId: json['lessonId'] as String? ?? '',
      unitId: json['unitId'] as int? ?? 0,
      unitTitle: json['unitTitle'] as String? ?? '',
      orderNum: json['orderNum'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      isPublished: json['isPublished'] as bool? ?? false,
      steps: stepsList
          .map((e) => StepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
