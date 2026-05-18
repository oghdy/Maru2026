import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfileModel?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  @override
  FutureOr<UserProfileModel?> build() async {
    return _fetchProfile();
  }

  Future<UserProfileModel?> _fetchProfile() async {
    final repository = ref.read(profileRepositoryProvider);
    return repository.getCurrentProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  Future<bool> updateProfile(String nickname) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.updateProfile(nickname);
      if (profile != null) {
        state = AsyncValue.data(profile);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
