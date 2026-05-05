import 'package:go_router/go_router.dart';
import 'package:screenblock/features/onboarding/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'splash', builder: (context, state) => const SplashScreen()),
    ],
  );
}