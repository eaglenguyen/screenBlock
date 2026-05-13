import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'UI/overlay_screen.dart';
import 'app_router.dart';
import 'core/constants/hivebox_names.dart';
import 'core/theme/app_theme.dart';
import 'data/models/blocked_app.dart';
import 'data/models/schedule.dart';
import 'data/models/streak.dart';
import 'data/models/timer_config.dart';
import 'data/models/usage_log.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Hive.initFlutter();

  // register adapters
  Hive.registerAdapter(TimerConfigAdapter());
  Hive.registerAdapter(BlockedAppAdapter());
  Hive.registerAdapter(UsageLogAdapter());
  Hive.registerAdapter(StreakAdapter());
  Hive.registerAdapter(ScheduleAdapter());


  // open boxes
  await Hive.openBox<TimerConfig>(HiveBoxNames.timerConfigs);
  await Hive.openBox<BlockedApp>(HiveBoxNames.blockedApps);
  await Hive.openBox<UsageLog>(HiveBoxNames.usageLogs);
  await Hive.openBox<Streak>(HiveBoxNames.streaks);
  await Hive.openBox(HiveBoxNames.settings);
  await Hive.openBox<Schedule>(HiveBoxNames.schedules);




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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScreenBlocker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.router,
    );

  }
}
