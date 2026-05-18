/// Request DTO for `/api/lab/explore`
class AiLabExploreRequestModel {
  final String inputText;
  final String category;

  AiLabExploreRequestModel({
    required this.inputText,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'inputText': inputText,
      'category': category,
    };
  }
}

/// Response DTO for `/api/lab/explore` (usually returns a List of these)
class AiLabExploreResponseModel {
  final String text;
  final String type;
  final String explanation;

  AiLabExploreResponseModel({
    required this.text,
    required this.type,
    required this.explanation,
  });

  factory AiLabExploreResponseModel.fromJson(Map<String, dynamic> json) {
    return AiLabExploreResponseModel(
      text: json['text'] ?? '',
      type: json['type'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

/// Request DTO for `/api/lab/combine`
class AiLabCombineRequestModel {
  final String inputText;
  final List<String> modifiers;

  AiLabCombineRequestModel({
    required this.inputText,
    required this.modifiers,
  });

  Map<String, dynamic> toJson() {
    return {
      'inputText': inputText,
      'modifiers': modifiers,
    };
  }
}

/// Response DTO for `/api/lab/combine`
class AiLabCombineResponseModel {
  final String text;
  final String englishTranslation;
  final String explanation;

  AiLabCombineResponseModel({
    required this.text,
    required this.englishTranslation,
    required this.explanation,
  });

  factory AiLabCombineResponseModel.fromJson(Map<String, dynamic> json) {
    return AiLabCombineResponseModel(
      text: json['text'] ?? '',
      englishTranslation: json['englishTranslation'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}
