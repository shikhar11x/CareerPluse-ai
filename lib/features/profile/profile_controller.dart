import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Rebuild only when the signed-in USER changes (not on token refresh).
    ref.watch(authStateProvider.select((s) => s.asData?.value.session?.user.id));
    if (ref.watch(authRepositoryProvider).currentSession == null) return null;
    return ref.watch(profileRepositoryProvider).fetch();
  }

  /// Throws on failure so the form can show the message.
  Future<void> save({
    String? fullName,
    String? education,
    String? targetRole,
    String? experienceLevel,
  }) async {
    final updated = await ref.read(profileRepositoryProvider).update(
          fullName: fullName,
          education: education,
          targetRole: targetRole,
          experienceLevel: experienceLevel,
        );
    state = AsyncData(updated);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);