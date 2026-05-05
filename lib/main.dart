import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_router.dart';
import 'core/constants/hivebox_names.dart';
import 'core/theme/app_theme.dart';
import 'data/models/blocked_app.dart';
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

  // open boxes
  await Hive.openBox<TimerConfig>(HiveBoxNames.timerConfigs);
  await Hive.openBox<BlockedApp>(HiveBoxNames.blockedApps);
  await Hive.openBox<UsageLog>(HiveBoxNames.usageLogs);
  await Hive.openBox<Streak>(HiveBoxNames.streaks);
  await Hive.openBox(HiveBoxNames.settings);



  runApp(const MyApp());
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
