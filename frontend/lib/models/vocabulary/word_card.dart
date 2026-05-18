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
  });

  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'] as int,
      koreanWord: json['koreanWord'] as String,
      primaryMeaning: json['primaryMeaning'] as String,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      audioUrl: json['audioUrl'] as String?,
      state: FsrsState.fromInt(json['state'] as int),
      reps: json['reps'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'koreanWord': koreanWord,
      'primaryMeaning': primaryMeaning,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
      'partOfSpeech': partOfSpeech,
      'audioUrl': audioUrl,
      'state': state.value,
      'reps': reps,
    };
  }
}
