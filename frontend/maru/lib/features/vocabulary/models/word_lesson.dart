class WordLesson {
  final int lessonNumber;
  final int totalWords;
  final int studiedWords;
  final bool isCompleted;

  WordLesson({
    required this.lessonNumber,
    required this.totalWords,
    required this.studiedWords,
    required this.isCompleted,
  });

  bool get isInProgress => !isCompleted && studiedWords > 0;

  factory WordLesson.fromJson(Map<String, dynamic> json) {
    return WordLesson(
      lessonNumber: json['lessonNumber'] ?? 0,
      totalWords: json['totalWords'] ?? 0,
      studiedWords: json['studiedWords'] ?? 0,
      // 서버는 `isCompleted`(VOC-1.2.3) 와 하위 호환 `completed` 를 함께 보낸다
      isCompleted: json['isCompleted'] ?? json['completed'] ?? false,
    );
  }
}
