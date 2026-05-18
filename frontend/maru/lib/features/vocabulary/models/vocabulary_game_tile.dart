class VocabularyGameTile {
  final String id;
  final int pairId;
  final String text;
  final String type; // "KOREAN" or "ENGLISH"
  bool isSelected;
  bool isMatched;

  VocabularyGameTile({
    required this.id,
    required this.pairId,
    required this.text,
    required this.type,
    this.isSelected = false,
    this.isMatched = false,
  });

  factory VocabularyGameTile.fromJson(Map<String, dynamic> json) {
    return VocabularyGameTile(
      id: json['id']?.toString() ?? '',
      pairId: (json['pairId'] is String) 
          ? int.parse(json['pairId']) 
          : (json['pairId'] as num).toInt(),
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  VocabularyGameTile copyWith({
    bool? isSelected,
    bool? isMatched,
  }) {
    return VocabularyGameTile(
      id: id,
      pairId: pairId,
      text: text,
      type: type,
      isSelected: isSelected ?? this.isSelected,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
