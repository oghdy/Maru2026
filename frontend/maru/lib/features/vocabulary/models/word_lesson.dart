class WordLesson {
  final int lessonNumber;
  final int totalWords;
  final bool isCompleted;

  WordLesson({
    required this.lessonNumber,
    required this.totalWords,
    required this.isCompleted,
  });

  factory WordLesson.fromJson(Map<String, dynamic> json) {
    return WordLesson(
      lessonNumber: json['lessonNumber'] ?? 0,
      totalWords: json['totalWords'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
