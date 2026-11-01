import 'korean_text.dart';

/// A ready-made situation card from GET /scenarios (web-demo API_CONTRACT 7.6). Only what the card
/// shows: starting one sends just its id and the difficulty, and the server fills in the rest.
class MissionScenario {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String roleEn;
  final String personalityEn;

  const MissionScenario({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.roleEn,
    required this.personalityEn,
  });

  factory MissionScenario.fromJson(Map<String, dynamic> json) {
    return MissionScenario(
      id: json['id'] as String,
      icon: json['icon'] is String ? json['icon'] as String : '',
      title: cleanAiText(json['title']) ?? '',
      description: cleanAiText(json['description']) ?? '',
      roleEn: cleanAiText(json['roleEn']) ?? '',
      personalityEn: cleanAiText(json['personalityEn']) ?? '',
    );
  }
}
