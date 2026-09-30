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
  });

  factory MissionClearanceModel.fromJson(Map<String, dynamic> json) {
    return MissionClearanceModel(
      id: json['id'],
      missionTitle: json['missionTitle'] ?? '',
      persona: json['persona'] ?? '',
      totalTurns: json['totalTurns'] ?? 0,
      goodExpressions: (json['goodExpressions'] as List?)
              ?.map((e) => ExpressionModel.fromJson(e))
              .toList() ??
          [],
      incorrectExpressions: (json['incorrectExpressions'] as List?)
              ?.map((e) => IncorrectExpressionModel.fromJson(e))
              .toList() ??
          [],
      turtleComment: json['turtleComment'] ?? '',
      nextPractice: json['nextPractice'] ?? '',
      clearedAt: json['clearedAt'] != null
          ? DateTime.parse(json['clearedAt'])
          : null,
      cleared: json['cleared'],
      resultReason: json['resultReason'],
      goalCondition: json['goalCondition'],
    );
  }
}

class ExpressionModel {
  final String expression;
  final String reason;

  ExpressionModel({required this.expression, required this.reason});

  factory ExpressionModel.fromJson(Map<String, dynamic> json) {
    return ExpressionModel(
      expression: json['expression'] ?? '',
      reason: json['reason'] ?? '',
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
      wrong: json['wrong'] ?? '',
      correct: json['correct'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}
