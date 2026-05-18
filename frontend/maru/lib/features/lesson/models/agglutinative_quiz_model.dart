class AgglutinativeElement {
  final String id;
  final bool isTarget;
  final String? text;
  final String? type;
  final List<String> correctRabbit;
  final List<String> correctTurtle;
  final String? turtleExplanation;

  AgglutinativeElement({
    required this.id,
    required this.isTarget,
    this.text,
    this.type,
    this.correctRabbit = const [],
    this.correctTurtle = const [],
    this.turtleExplanation,
  });

  factory AgglutinativeElement.fromJson(Map<String, dynamic> json) {
    return AgglutinativeElement(
      id: json['id'] as String? ?? json['text'] as String? ?? '', // simplified id handling
      isTarget: json['isTarget'] as bool? ?? false,
      text: json['text'] as String?,
      type: json['type'] as String?,
      correctRabbit: (json['correct_rabbit'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      correctTurtle: (json['correct_turtle'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      turtleExplanation: json['turtle_explanation'] as String?,
    );
  }
}

class AgglutinativeOption {
  final String id;
  final String text;
  final String mode; // 'rabbit' or 'turtle'
  final bool isUsed;

  AgglutinativeOption({
    required this.id,
    required this.text,
    required this.mode,
    this.isUsed = false,
  });

  factory AgglutinativeOption.fromJson(Map<String, dynamic> json) {
    return AgglutinativeOption(
      id: json['id'] as String? ?? json['text'] as String? ?? '', // simplified id 
      text: json['text'] as String? ?? '',
      mode: json['mode'] as String? ?? 'rabbit',
    );
  }
  
  AgglutinativeOption copyWith({bool? isUsed}) {
    return AgglutinativeOption(
      id: id,
      text: text,
      mode: mode,
      isUsed: isUsed ?? this.isUsed,
    );
  }
}

class AgglutinativeQuizData {
  final String sentence;
  final String translation;
  final List<AgglutinativeElement> elements;
  final List<AgglutinativeOption> options;

  AgglutinativeQuizData({
    required this.sentence,
    required this.translation,
    required this.elements,
    required this.options,
  });

  factory AgglutinativeQuizData.fromJson(Map<String, dynamic> json) {
    return AgglutinativeQuizData(
      sentence: json['sentence'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => AgglutinativeElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => AgglutinativeOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
