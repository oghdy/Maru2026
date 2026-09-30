enum FsrsState {
  newCard(0),
  learning(1),
  review(2),
  relearning(3);

  final int value;
  const FsrsState(this.value);

  static FsrsState fromInt(int value) {
    return FsrsState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FsrsState.newCard,
    );
  }
}

class WordCard {
  final int id;
  final String koreanWord;
  final String primaryMeaning;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? partOfSpeech;
  final String? audioUrl;
  final FsrsState state;
  final int reps;

  /// 평가 버튼별 다음 복습까지 라벨 (예: {"AGAIN":"5m","GOOD":"4d"}), VOC-1.3.3.
  final Map<String, String>? nextIntervals;

  /// Word Study(LESSON) 에서 평가가 스케줄에 반영되는지.
  /// 서버는 반영 안 되는 단어(이미 학습 + 복습일 전)에 nextIntervals=null 을 준다.
  /// 필드가 아예 없으면(구버전 서버) 새 단어일 때만 반영된다고 본다.
  final bool ratingAppliesInLesson;

  WordCard({
    required this.id,
    required this.koreanWord,
    required this.primaryMeaning,
    this.exampleSentence,
    this.exampleTranslation,
    this.partOfSpeech,
    this.audioUrl,
    required this.state,
    required this.reps,
    this.nextIntervals,
    required this.ratingAppliesInLesson,
  });

  factory WordCard.fromJson(Map<String, dynamic> json) {
    final state = FsrsState.fromInt(json['state'] as int);
    final rawIntervals = json['nextIntervals'];
    return WordCard(
      id: json['id'] as int,
      koreanWord: json['koreanWord'] as String,
      primaryMeaning: json['primaryMeaning'] as String,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      audioUrl: json['audioUrl'] as String?,
      state: state,
      reps: json['reps'] as int,
      nextIntervals: rawIntervals is Map
          ? rawIntervals.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
      ratingAppliesInLesson: json.containsKey('nextIntervals')
          ? rawIntervals != null
          : state == FsrsState.newCard,
    );
  }
}
