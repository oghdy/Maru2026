import 'korean_text.dart';

class ChatTurnResponse {
  final String? rabbitReply;
  final String? rabbitReplyEn;
  final CorrectionModel correction;
  final String missionStatus; // in_progress | cleared | failed
  // API_CONTRACT 1-7 A: server-side turn count and limits (null on older servers).
  final int? userTurn;
  final int? maxTurns;
  final String? zone; // A | B | C
  // web-demo API_CONTRACT 7.3. completedSteps: step numbers from 1, null on older servers.
  final List<int>? completedSteps;
  final String? praise;
  final String? praiseEn;

  ChatTurnResponse({
    this.rabbitReply,
    this.rabbitReplyEn,
    required this.correction,
    required this.missionStatus,
    this.userTurn,
    this.maxTurns,
    this.zone,
    this.completedSteps,
    this.praise,
    this.praiseEn,
  });

  factory ChatTurnResponse.fromJson(Map<String, dynamic> json) {
    return ChatTurnResponse(
      rabbitReply: cleanAiText(json['rabbitReply']),
      rabbitReplyEn: cleanAiText(json['rabbitReplyEn']),
      correction: CorrectionModel.fromJson(json['correction']),
      missionStatus: json['missionStatus'] ?? 'in_progress',
      userTurn: json['userTurn'],
      maxTurns: json['maxTurns'],
      zone: json['zone'],
      completedSteps: (json['completedSteps'] as List?)?.whereType<int>().toList(),
      praise: cleanAiText(json['praise']),
      praiseEn: cleanAiText(json['praiseEn']),
    );
  }
}

class CorrectionModel {
  final String severity; // immediate | side | none
  final String issueType; // honorific_mismatch | grammar_error | vocabulary | pragmatic | off_topic | none
  final String? userInputProblematic;
  final String? correctExpression;
  final String? turtleFeedback;
  final String? turtleFeedbackEn;

  CorrectionModel({
    required this.severity,
    required this.issueType,
    this.userInputProblematic,
    this.correctExpression,
    this.turtleFeedback,
    this.turtleFeedbackEn,
  });

  factory CorrectionModel.fromJson(Map<String, dynamic> json) {
    return CorrectionModel(
      severity: json['severity'] ?? 'none',
      issueType: json['issueType'] ?? 'none',
      userInputProblematic: cleanAiText(json['userInputProblematic']),
      correctExpression: cleanAiText(json['correctExpression']),
      turtleFeedback: cleanAiText(json['turtleFeedback']),
      turtleFeedbackEn: cleanAiText(json['turtleFeedbackEn']),
    );
  }
}
