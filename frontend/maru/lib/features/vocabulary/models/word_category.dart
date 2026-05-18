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
    final rawTitle = json['title'] as String;
    String englishTitle = rawTitle;
    switch (rawTitle) {
      case '쇼핑/경제':
        englishTitle = 'Shopping & Economy';
        break;
      case '가족/인물':
        englishTitle = 'Family & People';
        break;
      case '기타/사물':
        englishTitle = 'Others & Objects';
        break;
      case '동작/상태':
        englishTitle = 'Actions & States';
        break;
      case '시간':
        englishTitle = 'Time';
        break;
      case '감정':
        englishTitle = 'Emotions';
        break;
      case '학교/교육':
        englishTitle = 'School & Education';
        break;
      case '날씨/자연':
        englishTitle = 'Weather & Nature';
        break;
      case '식생활':
        englishTitle = 'Food & Eating';
        break;
      case '주생활':
        englishTitle = 'Housing & Living';
        break;
      case '여가/문화':
        englishTitle = 'Leisure & Culture';
        break;
      case '언어/소통':
        englishTitle = 'Language & Communication';
        break;
      case '직업/직장':
        englishTitle = 'Jobs & Workplace';
        break;
      case '건강/의료':
        englishTitle = 'Health & Medical';
        break;
      case '직업/사회':
        englishTitle = 'Jobs & Society';
        break;
      case '신체':
        englishTitle = 'Body';
        break;
      case '음식':
        englishTitle = 'Food';
        break;
      case '동물/식물':
        englishTitle = 'Animals & Plants';
        break;
      case '숫자/수량':
        englishTitle = 'Numbers & Quantities';
        break;
      case '장소':
        englishTitle = 'Places';
        break;
    }

    return WordCategory(
      id: json['id'] as int,
      title: englishTitle,
      level: json['level'] as String,
      totalWords: json['totalWords'] as int,
    );
  }
}
