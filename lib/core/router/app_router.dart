import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/interview/interview_screen.dart';
import '../../features/interview/results_screen.dart';
import '../../features/interview/room_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../widgets/placeholder_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const setup = '/setup';
  static const home = '/home';
  static const interview = '/interview';
  static const resume = '/resume';
  static const roadmap = '/roadmap';
  static const profile = '/profile';
  // Full-screen routes (outside the tab shell). Append "/<interviewId>".
  static const room = '/room';
  static const results = '/results';
}

Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          pageBuilder: (context, state) => NoTransitionPage<void>(child: screen),
        ),
      ],
    );

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever auth or profile state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(profileProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == Routes.splash) return null;

      final signedIn = ref.read(authRepositoryProvider).currentSession != null;
      final isPublic = loc == Routes.onboarding || loc == Routes.auth;
      if (!signedIn) return isPublic ? null : Routes.auth;

      final profileState = ref.read(profileProvider);
      // While loading or on error, stay put. Home shows the error with a retry.
      if (profileState.isLoading || profileState.hasError) {
        return isPublic ? Routes.home : null;
      }
      final complete = profileState.asData?.value?.isComplete ?? false;
      if (!complete) return loc == Routes.setup ? null : Routes.setup;
      if (isPublic || loc == Routes.setup) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (c, s) => _fade(s, const SplashScreen()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (c, s) => _fade(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.auth,
        pageBuilder: (c, s) => _fade(s, const AuthScreen()),
      ),
      GoRoute(
        path: Routes.setup,
        pageBuilder: (c, s) => _fade(s, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: '${Routes.room}/:id',
        pageBuilder: (c, s) =>
            _fade(s, RoomScreen(interviewId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '${Routes.results}/:id',
        pageBuilder: (c, s) =>
            _fade(s, ResultsScreen(interviewId: s.pathParameters['id']!)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _branch(Routes.home, const DashboardScreen()),
          _branch(Routes.interview, const InterviewScreen()),
          _branch(
            Routes.resume,
            const PlaceholderScreen(
              title: 'Resume analysis',
              icon: Icons.description_rounded,
              phase: 'Phase 5',
            ),
          ),
          _branch(
            Routes.roadmap,
            const PlaceholderScreen(
              title: 'Career roadmap',
              icon: Icons.route_rounded,
              phase: 'Phase 5',
            ),
          ),
          _branch(Routes.profile, const ProfileScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});