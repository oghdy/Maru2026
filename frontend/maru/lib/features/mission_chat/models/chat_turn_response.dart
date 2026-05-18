class ChatTurnResponse {
  final String? rabbitReply;
  final String? rabbitReplyEn;
  final CorrectionModel correction;
  final String missionStatus;

  ChatTurnResponse({
    this.rabbitReply,
    this.rabbitReplyEn,
    required this.correction,
    required this.missionStatus,
  });

  factory ChatTurnResponse.fromJson(Map<String, dynamic> json) {
    return ChatTurnResponse(
      rabbitReply: json['rabbitReply'],
      rabbitReplyEn: json['rabbitReplyEn'],
      correction: CorrectionModel.fromJson(json['correction']),
      missionStatus: json['missionStatus'] ?? 'in_progress',
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
      userInputProblematic: json['userInputProblematic'],
      correctExpression: json['correctExpression'],
      turtleFeedback: json['turtleFeedback'],
      turtleFeedbackEn: json['turtleFeedbackEn'],
    );
  }
}
