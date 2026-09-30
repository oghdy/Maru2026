class WordCategory {
  final int id;

  /// 화면에 보이는 영어 덱 이름 (번역이 없으면 서버 원문)
  final String title;

  /// 서버(DB)의 한국어 덱 이름, 예: "쇼핑/경제"
  final String koreanTitle;
  final String level;
  final int totalWords;

  WordCategory({
    required this.id,
    required this.title,
    required this.koreanTitle,
    required this.level,
    required this.totalWords,
  });

  /// DB `word_categories.title` 14개 → 영어 이름 (2026-09-30 기준 전부 포함)
  static const Map<String, String> _englishTitles = {
    '쇼핑/경제': 'Shopping & Economy',
    '가족/인물': 'Family & People',
    '기타/사물': 'Others & Objects',
    '동작/상태': 'Actions & States',
    '시간': 'Time',
    '감정': 'Emotions',
    '학교/교육': 'School & Education',
    '날씨/자연': 'Weather & Nature',
    '직업/사회': 'Jobs & Society',
    '신체': 'Body',
    '음식': 'Food',
    '동물/식물': 'Animals & Plants',
    '숫자/수량': 'Numbers & Quantities',
    '장소': 'Places',
  };

  factory WordCategory.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String;
    return WordCategory(
      id: json['id'] as int,
      title: _englishTitles[rawTitle] ?? rawTitle,
      koreanTitle: rawTitle,
      level: json['level'] as String,
      totalWords: json['totalWords'] as int,
    );
  }
}
