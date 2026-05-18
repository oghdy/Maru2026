class UserProfileModel {
  final int id;
  final String oauthId;
  final String email;
  final String oauthProvider;
  final String? nickname;
  final String? profileImageUrl;

  UserProfileModel({
    required this.id,
    required this.oauthId,
    required this.email,
    required this.oauthProvider,
    this.nickname,
    this.profileImageUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      oauthId: json['oauthId'],
      email: json['email'] ?? '',
      oauthProvider: json['oauthProvider'] ?? 'unknown',
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  bool get isProfileComplete => nickname != null && nickname!.trim().isNotEmpty;
}
