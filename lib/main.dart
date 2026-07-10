import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pausenow/providers/blocking_service_provider.dart';
import 'package:pausenow/providers/premium_provider.dart';
import 'package:pausenow/services/notification_service.dart';
import 'package:pausenow/services/revenuecat_service.dart';
import 'package:pausenow/services/schedule_checker.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:rive/rive.dart';
import 'UI/home/widgets/xp_animation.dart';
import 'app_router.dart';
import 'core/constants/hivebox_names.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme.notifier.dart';
import 'data/models/block_session.dart';
import 'data/models/blocked_app.dart';
import 'data/models/schedule.dart';
import 'data/models/streak.dart';
import 'data/models/time_limit_config.dart';
import 'data/models/timer_config.dart';
import 'data/models/usage_log.dart';

import 'package:timezone/data/latest.dart' as tz_data;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones(); // 👈
  await NotificationService.instance.initialize(); // 👈
  await RiveNative.init(); // 👈 required for 0.14.x


  await Hive.initFlutter();
  await XpAnimation.instance.init();


  // register adapters
  Hive.registerAdapter(TimerConfigAdapter());
  Hive.registerAdapter(BlockedAppAdapter());
  Hive.registerAdapter(UsageLogAdapter());
  Hive.registerAdapter(StreakAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(BlockSessionAdapter());
  Hive.registerAdapter(TimeLimitConfigAdapter());


  // open boxes
  await Hive.openBox<TimerConfig>(HiveBoxNames.timerConfigs);
  await Hive.openBox<BlockedApp>(HiveBoxNames.blockedApps);
  await Hive.openBox<UsageLog>(HiveBoxNames.usageLogs);
  await Hive.openBox<Streak>(HiveBoxNames.streaks);
  await Hive.openBox(HiveBoxNames.settings);
  await Hive.openBox<Schedule>(HiveBoxNames.schedules);
  await Hive.openBox<BlockSession>(HiveBoxNames.blockSessions);
  await Hive.openBox<TimeLimitConfig>(HiveBoxNames.timeLimitConfigs);

  final settingsBox = Hive.box(HiveBoxNames.settings);
  if (settingsBox.get('installDate') == null) {
    await settingsBox.put('installDate', DateTime.now().millisecondsSinceEpoch);
  }

  // 👇 initialize RevenueCat before app launches
  await RevenueCatService.instance.initialize();

  //PostHog setup
  final config = PostHogConfig('phc_B87VKMMuFwotFDUuDJuGiKpNWSTPQfEFd3YrrLQLKJnJ')
    ..host = 'https://us.i.posthog.com'
    ..debug = kDebugMode
    ..captureApplicationLifecycleEvents = true;
  await Posthog().setup(config);



  runApp(
      const ProviderScope(
        child: MyApp(),
      )
  );
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // start schedule checker
    final blockingService = ref.read(blockingServiceProvider);
    ScheduleChecker.instance.start(blockingService);

    final themeMode = ref.watch(themeProvider); // 👈 add this


    ref.listen(premiumProvider, (prev, next) {
      final isPremium = next.valueOrNull ?? false;
      // sync to native
      if (Platform.isIOS) {
        const channel = MethodChannel('com.eagle.pausenow/ios_blocking');
        channel.invokeMethod('setPremiumStatus', {'isPremium': isPremium});
      }
    });

    return MaterialApp.router(
      title: 'pause now',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
