class UserStatsModel {
  final int totalLessonsCompleted;
  final int totalStudyMinutes;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalStarsEarned;
  final DateTime? lastStudyDate;

  UserStatsModel({
    required this.totalLessonsCompleted,
    required this.totalStudyMinutes,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalStarsEarned,
    this.lastStudyDate,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalStudyMinutes: json['totalStudyMinutes'] ?? 0,
      currentStreakDays: json['currentStreakDays'] ?? 0,
      longestStreakDays: json['longestStreakDays'] ?? 0,
      totalStarsEarned: json['totalStarsEarned'] ?? 0,
      lastStudyDate: json['lastStudyDate'] != null ? DateTime.tryParse(json['lastStudyDate']) : null,
    );
  }
}
