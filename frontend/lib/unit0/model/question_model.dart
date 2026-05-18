/// Question data model
/// Represents a single question within a quiz step
class Question {
  final String questionType;
  final Map<String, dynamic> content;
  final Map<String, dynamic> answer;

  Question({
    required this.questionType,
    required this.content,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionType: json['question_type'] as String,
      content: json['content'] as Map<String, dynamic>,
      answer: json['answer'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_type': questionType,
      'content': content,
      'answer': answer,
    };
  }
}

/// Question type constants
class QuestionType {
  static const String multipleChoice = 'multiple_choice';
  static const String audioChoice = 'audio_choice';
  static const String fillBlank = 'fill_blank';
  static const String listening = 'listening';
  static const String dragDrop = 'drag_drop';
}

