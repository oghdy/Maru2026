import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/demo_mode.dart';
import '../../../core/demo/guest_session.dart';
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
    final profile = await repository.getCurrentProfile();
    if (profile == null && kDemoMode) {
      // The saved guest no longer exists on the server (demo data was reset): become a new guest.
      try {
        await ref.read(guestSessionProvider).issueToken();
        return repository.getCurrentProfile();
      } on GuestEntryFailure {
        return null;
      }
    }
    return profile;
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
