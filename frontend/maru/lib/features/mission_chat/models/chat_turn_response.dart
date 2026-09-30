class ChatTurnResponse {
  final String? rabbitReply;
  final String? rabbitReplyEn;
  final CorrectionModel correction;
  final String missionStatus; // in_progress | cleared | failed
  // API_CONTRACT 1-7 A: server-side turn count and limits (null on older servers).
  final int? userTurn;
  final int? maxTurns;
  final String? zone; // A | B | C

  ChatTurnResponse({
    this.rabbitReply,
    this.rabbitReplyEn,
    required this.correction,
    required this.missionStatus,
    this.userTurn,
    this.maxTurns,
    this.zone,
  });

  factory ChatTurnResponse.fromJson(Map<String, dynamic> json) {
    return ChatTurnResponse(
      rabbitReply: CorrectionModel._text(json['rabbitReply']),
      rabbitReplyEn: CorrectionModel._text(json['rabbitReplyEn']),
      correction: CorrectionModel.fromJson(json['correction']),
      missionStatus: json['missionStatus'] ?? 'in_progress',
      userTurn: json['userTurn'],
      maxTurns: json['maxTurns'],
      zone: json['zone'],
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
      userInputProblematic: _text(json['userInputProblematic']),
      correctExpression: _text(json['correctExpression']),
      turtleFeedback: _text(json['turtleFeedback']),
      turtleFeedbackEn: _text(json['turtleFeedbackEn']),
    );
  }

  // The AI sometimes sends the string "null" or blanks; treat those as missing.
  static String? _text(dynamic v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty || t == 'null' ? null : t;
  }
}
