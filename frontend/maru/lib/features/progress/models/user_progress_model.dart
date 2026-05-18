class UserProgressRequestModel {
  final String status;
  final int currentStep;
  final int score;
  final int timeSpentSeconds;

  UserProgressRequestModel({
    required this.status,
    required this.currentStep,
    required this.score,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'currentStep': currentStep,
      'score': score,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}

class UserProgressResponseModel {
  final String lessonId;
  final String status;
  final int currentStep;
  final int score;
  final int starsEarned;
  final int attempts;

  UserProgressResponseModel({
    required this.lessonId,
    required this.status,
    required this.currentStep,
    required this.score,
    required this.starsEarned,
    required this.attempts,
  });

  factory UserProgressResponseModel.fromJson(Map<String, dynamic> json) {
    return UserProgressResponseModel(
      lessonId: json['lessonId'],
      status: json['status'],
      currentStep: json['currentStep'] ?? 0,
      score: json['score'] ?? 0,
      starsEarned: json['starsEarned'] ?? 0,
      attempts: json['attempts'] ?? 0,
    );
  }
}
