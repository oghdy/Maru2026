class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String? contentEn;
  final bool isTurtleIntervention;
  final String? turtleFeedback;
  final String? turtleFeedbackEn;

  ChatMessage({
    required this.role,
    required this.content,
    this.contentEn,
    this.isTurtleIntervention = false,
    this.turtleFeedback,
    this.turtleFeedbackEn,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
