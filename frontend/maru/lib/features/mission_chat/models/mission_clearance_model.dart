import 'mission_difficulty.dart';

import 'korean_text.dart';

class MissionClearanceModel {
  final int? id;
  final String missionTitle;
  final String persona;
  final int totalTurns;
  final List<ExpressionModel> goodExpressions;
  final List<IncorrectExpressionModel> incorrectExpressions;
  final String turtleComment;
  final String nextPractice;
  final DateTime? clearedAt;
  // API_CONTRACT 1-7 D: goal judged by the turtle coach. null = issued before judging existed.
  final bool? cleared;
  final String? resultReason;
  final String? goalCondition;
  // API_CONTRACT 1-8 D: null for reports issued before difficulty existed.
  final MissionDifficulty? difficulty;

  MissionClearanceModel({
    this.id,
    required this.missionTitle,
    required this.persona,
    required this.totalTurns,
    required this.goodExpressions,
    required this.incorrectExpressions,
    required this.turtleComment,
    required this.nextPractice,
    this.clearedAt,
    this.cleared,
    this.resultReason,
    this.goalCondition,
    this.difficulty,
  });

  factory MissionClearanceModel.fromJson(Map<String, dynamic> json) {
    return MissionClearanceModel(
      id: json['id'],
      missionTitle: cleanAiText(json['missionTitle']) ?? '',
      persona: cleanAiText(json['persona']) ?? '',
      totalTurns: json['totalTurns'] ?? 0,
      goodExpressions: (json['goodExpressions'] as List?)
              ?.map((e) => ExpressionModel.fromJson(e))
              .toList() ??
          [],
      incorrectExpressions: (json['incorrectExpressions'] as List?)
              ?.map((e) => IncorrectExpressionModel.fromJson(e))
              .toList() ??
          [],
      turtleComment: cleanAiText(json['turtleComment']) ?? '',
      nextPractice: cleanAiText(json['nextPractice']) ?? '',
      clearedAt: json['clearedAt'] != null
          ? DateTime.parse(json['clearedAt'])
          : null,
      cleared: json['cleared'],
      resultReason: cleanAiText(json['resultReason']),
      goalCondition: cleanAiText(json['goalCondition']),
      difficulty: MissionDifficulty.tryParse(json['difficulty']),
    );
  }
}

class ExpressionModel {
  final String expression;
  final String reason;

  ExpressionModel({required this.expression, required this.reason});

  factory ExpressionModel.fromJson(Map<String, dynamic> json) {
    return ExpressionModel(
      expression: cleanAiText(json['expression']) ?? '',
      reason: cleanAiText(json['reason']) ?? '',
    );
  }
}

class IncorrectExpressionModel {
  final String wrong;
  final String correct;
  final String explanation;

  IncorrectExpressionModel({
    required this.wrong,
    required this.correct,
    required this.explanation,
  });

  factory IncorrectExpressionModel.fromJson(Map<String, dynamic> json) {
    return IncorrectExpressionModel(
      wrong: cleanAiText(json['wrong']) ?? '',
      correct: cleanAiText(json['correct']) ?? '',
      explanation: cleanAiText(json['explanation']) ?? '',
    );
  }
}
