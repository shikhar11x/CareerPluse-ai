import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'interview_models.dart';
import 'interview_repository.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>(
  (ref) => InterviewRepository(ref.watch(apiClientProvider)),
);

/// Recent interviews (newest first). Invalidate after create / complete / delete.
final interviewHistoryProvider = FutureProvider<List<InterviewSummary>>((ref) {
  // Refetch when the signed-in USER changes, not on token refresh.
  ref.watch(authStateProvider.select((s) => s.asData?.value.session?.user.id));
  return ref.watch(interviewRepositoryProvider).list();
});

/// Counts and average scores for the dashboard.
final progressProvider = FutureProvider<Progress>((ref) {
  ref.watch(authStateProvider.select((s) => s.asData?.value.session?.user.id));
  return ref.watch(interviewRepositoryProvider).progress();
});