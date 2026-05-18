class WordCategory {
  final int id;
  final String title;
  final String level;
  final int totalWords;

  WordCategory({
    required this.id,
    required this.title,
    required this.level,
    required this.totalWords,
  });

  factory WordCategory.fromJson(Map<String, dynamic> json) {
    return WordCategory(
      id: json['id'] as int,
      title: json['title'] as String,
      level: json['level'] as String,
      totalWords: json['totalWords'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'totalWords': totalWords,
    };
  }
}
