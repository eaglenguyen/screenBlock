import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:screenblock/providers/blocking_service_provider.dart';
import 'package:screenblock/services/schedule_checker.dart';
import 'package:screenblock/services/xp_animation.dart';
import 'UI/overlay_screen.dart';
import 'app_router.dart';
import 'core/constants/hivebox_names.dart';
import 'core/theme/app_theme.dart';
import 'data/models/block_session.dart';
import 'data/models/blocked_app.dart';
import 'data/models/schedule.dart';
import 'data/models/streak.dart';
import 'data/models/timer_config.dart';
import 'data/models/usage_log.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Hive.initFlutter();
  await XpAnimation.instance.init();


  // register adapters
  Hive.registerAdapter(TimerConfigAdapter());
  Hive.registerAdapter(BlockedAppAdapter());
  Hive.registerAdapter(UsageLogAdapter());
  Hive.registerAdapter(StreakAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(BlockSessionAdapter());


  // open boxes
  await Hive.openBox<TimerConfig>(HiveBoxNames.timerConfigs);
  await Hive.openBox<BlockedApp>(HiveBoxNames.blockedApps);
  await Hive.openBox<UsageLog>(HiveBoxNames.usageLogs);
  await Hive.openBox<Streak>(HiveBoxNames.streaks);
  await Hive.openBox(HiveBoxNames.settings);
  await Hive.openBox<Schedule>(HiveBoxNames.schedules);
  await Hive.openBox<BlockSession>(HiveBoxNames.blockSessions);


  // 👇 temporary — forces onboarding every launch for testing
  final settings = Hive.box(HiveBoxNames.settings);
  await settings.put('onboardingComplete', false);


  runApp(
      const ProviderScope(
        child: MyApp(),
      )
  );
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // start schedule checker
    final blockingService = ref.read(blockingServiceProvider);
    ScheduleChecker.instance.start(blockingService);

    return MaterialApp.router(
      title: 'ScreenBlocker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );
  }
}
