class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String? contentEn;
  final bool isTurtleIntervention;
  final String? turtleFeedback;
  final String? turtleFeedbackEn;
  final String? turtleIssueType; // issueType of the side correction (yellow card)
  // User message that the turtle stopped (immediate correction). Shown, but not sent as history.
  final bool isRejected;
  // User message that failed to reach the server. Shown with a retry button, not sent as history.
  final bool sendFailed;

  ChatMessage({
    required this.role,
    required this.content,
    this.contentEn,
    this.isTurtleIntervention = false,
    this.turtleFeedback,
    this.turtleFeedbackEn,
    this.turtleIssueType,
    this.isRejected = false,
    this.sendFailed = false,
  });

  /// Whether this message is part of the conversation the server should see.
  bool get countsAsHistory => role != 'system' && !isRejected && !sendFailed;

  ChatMessage copyWith({bool? isRejected, bool? sendFailed}) {
    return ChatMessage(
      role: role,
      content: content,
      contentEn: contentEn,
      isTurtleIntervention: isTurtleIntervention,
      turtleFeedback: turtleFeedback,
      turtleFeedbackEn: turtleFeedbackEn,
      turtleIssueType: turtleIssueType,
      isRejected: isRejected ?? this.isRejected,
      sendFailed: sendFailed ?? this.sendFailed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
