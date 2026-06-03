import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:screenblock/features/onboarding/onboarding_welcome_flow.dart';

import 'core/constants/hivebox_names.dart';
import 'features/bottomNav/shell_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/schedule/schedule_screen.dart';
import 'features/onboarding/onboarding_chat_screen.dart';
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

      // only redirect to onboarding if not already there
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
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/stats',
            name: 'stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // outside shell
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
  );
}