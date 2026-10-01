import 'korean_text.dart';

class SuggestionResponse {
  final List<SuggestionDto> suggestions;

  SuggestionResponse({required this.suggestions});

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionResponse(
      suggestions: (json['suggestions'] as List)
          .map((e) => SuggestionDto.fromJson(e))
          .toList(),
    );
  }
}

class SuggestionDto {
  final String korean;
  final String english;

  SuggestionDto({required this.korean, required this.english});

  factory SuggestionDto.fromJson(Map<String, dynamic> json) {
    return SuggestionDto(
      korean: cleanAiText(json['korean']) ?? '',
      english: cleanAiText(json['english']) ?? '',
    );
  }
}
