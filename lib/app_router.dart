import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'features/bottomNav/shell_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/schedule/schedule_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/timer/timer_screen.dart';

class AppRouter {
  AppRouter._();


  static final router = GoRouter(
    initialLocation: '/home',
    routes: [

      // ShellRoute wraps all tab screens
      // ShellScreen renders once and stays mounted
      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
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

      // routes outside the shell — no bottom nav
      GoRoute(
        path: '/timer-config',
        name: 'timer-config',
        builder: (context, state) => const TimerScreen(),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/app-picker',
        name: 'app-picker',
        builder: (context, state) => const SizedBox(),
        // app picker is shown as bottom sheet not a route
      ),
    ],
  );
}