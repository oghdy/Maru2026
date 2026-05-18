import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfileModel?> getCurrentProfile() async {
    try {
      final response = await _dio.get('/api/me');
      if (response.statusCode == 200 && response.data != null) {
        return UserProfileModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserProfileModel?> updateProfile(String nickname, {String? profileImageUrl}) async {
    try {
      final payload = {'nickname': nickname};
      if (profileImageUrl != null) payload['profileImageUrl'] = profileImageUrl;
      
      final response = await _dio.put('/api/me/profile', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        return UserProfileModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
