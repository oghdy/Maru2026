/// Mission difficulty (API_CONTRACT `difficulty`: "easy" | "normal" | "hard"). MSN-1.8.
enum MissionDifficulty {
  easy('easy', 'Easy', '🌱', 'Short, simple sentences. Great for beginners.'),
  normal('normal', 'Normal', '🌿', 'Everyday Korean in one or two sentences.'),
  hard('hard', 'Hard', '🔥', 'Natural, longer replies like a real chat.');

  final String apiValue;
  final String label;
  final String emoji;
  final String description;

  const MissionDifficulty(this.apiValue, this.label, this.emoji, this.description);

  static const MissionDifficulty fallback = MissionDifficulty.easy;

  /// null when the server sent nothing (e.g. reports issued before difficulty existed).
  static MissionDifficulty? tryParse(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    for (final d in values) {
      if (d.apiValue == v) return d;
    }
    return null;
  }
}
