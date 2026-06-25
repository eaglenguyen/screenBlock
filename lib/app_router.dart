import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'core/constants/hivebox_names.dart';
import 'features/bottomNav/shell_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/schedule/schedule_screen.dart';
import 'features/onboarding/onboarding_welcome_flow.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final box = Hive.box(HiveBoxNames.settings);

      final onboardingComplete = box.get(
        'onboardingComplete',
        defaultValue: false,
      ) as bool;

      // redirect to onboarding if not complete
      if (!onboardingComplete &&
          !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // onboarding outside shell
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingWelcomeFlow(),
      ),

      // shell wraps tab screens
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ScheduleScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          GoRoute(
            path: '/stats',
            name: 'stats',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StatsScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        ],
      ),

      // paywall outside shell — hard gate after onboarding
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
}