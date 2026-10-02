import 'korean_text.dart';
import 'mission_difficulty.dart';

class MissionSetupResponse {
  final Persona persona;
  final Mission mission;
  final String? adjustmentNotice;
  // API_CONTRACT 1-8 B: server echo of the difficulty. Sent back unchanged with every /chat,
  // /suggestion and /clearance (MSN-1.8.5) — kept as the raw string so nothing is lost.
  final String? difficulty;
  // Top-level fields this model doesn't know yet; echoed back so the server never loses them.
  final Map<String, dynamic> _unknown;

  static const _known = {'persona', 'mission', 'adjustmentNotice', 'difficulty'};

  MissionSetupResponse({
    required this.persona,
    required this.mission,
    this.adjustmentNotice,
    this.difficulty,
    Map<String, dynamic> unknown = const {},
  }) : _unknown = unknown;

  /// null for setups from servers that don't send it yet (the server treats that as easy).
  MissionDifficulty? get difficultyLevel => MissionDifficulty.tryParse(difficulty);

  factory MissionSetupResponse.fromJson(Map<String, dynamic> json) {
    return MissionSetupResponse(
      persona: Persona.fromJson(json['persona']),
      mission: Mission.fromJson(json['mission']),
      adjustmentNotice: cleanAiText(json['adjustmentNotice']),
      difficulty: json['difficulty'] is String ? json['difficulty'] as String : null,
      unknown: {
        for (final e in json.entries)
          if (!_known.contains(e.key)) e.key: e.value,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ..._unknown,
      'persona': persona.toJson(),
      'mission': mission.toJson(),
      'adjustmentNotice': adjustmentNotice,
      if (difficulty != null) 'difficulty': difficulty,
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
