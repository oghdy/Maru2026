import 'korean_text.dart';

class MissionSetupResponse {
  final Persona persona;
  final Mission mission;
  final String? adjustmentNotice;

  MissionSetupResponse({
    required this.persona,
    required this.mission,
    this.adjustmentNotice,
  });

  factory MissionSetupResponse.fromJson(Map<String, dynamic> json) {
    return MissionSetupResponse(
      persona: Persona.fromJson(json['persona']),
      mission: Mission.fromJson(json['mission']),
      adjustmentNotice: cleanAiText(json['adjustmentNotice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'persona': persona.toJson(),
      'mission': mission.toJson(),
      'adjustmentNotice': adjustmentNotice,
    };
  }
}

class Persona {
  final String role;
  final String personality;
  final String speechStyle;
  final String honorificLevel;
  final String firstMessage;
  final String firstMessageEn;

  Persona({
    required this.role,
    required this.personality,
    required this.speechStyle,
    required this.honorificLevel,
    required this.firstMessage,
    required this.firstMessageEn,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      role: cleanAiText(json['role']) ?? '',
      personality: cleanAiText(json['personality']) ?? '',
      speechStyle: cleanAiText(json['speechStyle']) ?? '',
      honorificLevel: cleanAiText(json['honorificLevel']) ?? '',
      firstMessage: cleanAiText(json['firstMessage']) ?? '',
      firstMessageEn: cleanAiText(json['firstMessageEn']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'personality': personality,
      'speechStyle': speechStyle,
      'honorificLevel': honorificLevel,
      'firstMessage': firstMessage,
      'firstMessageEn': firstMessageEn,
    };
  }
}

class Mission {
  final String title;
  final String description;
  final ClearCondition clearCondition;
  final int minTurns;

  Mission({
    required this.title,
    required this.description,
    required this.clearCondition,
    required this.minTurns,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      title: cleanAiText(json['title']) ?? '',
      description: cleanAiText(json['description']) ?? '',
      clearCondition: ClearCondition.fromJson(json['clearCondition']),
      minTurns: json['minTurns'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'clearCondition': clearCondition.toJson(),
      'minTurns': minTurns,
    };
  }
}

class ClearCondition {
  final String goalCondition;
  final String languageCondition;

  ClearCondition({
    required this.goalCondition,
    required this.languageCondition,
  });

  factory ClearCondition.fromJson(Map<String, dynamic> json) {
    return ClearCondition(
      goalCondition: cleanAiText(json['goalCondition']) ?? '',
      languageCondition: cleanAiText(json['languageCondition']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalCondition': goalCondition,
      'languageCondition': languageCondition,
    };
  }
}
