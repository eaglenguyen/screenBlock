import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );
    await _plugin.initialize(settings: initSettings);

    // 👇 create channels for Android 8+ (API 26+)
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'subscription_expiry',
        'Subscription Expiry',
        description: 'Notifies when subscription is about to expire',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'pomodoro',
        'Pomodoro Timer',
        description: 'Notifies when Pomodoro work or break ends',
        importance: Importance.high,
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id); // 👈 named parameter
  }

  // 👇 new — request exact alarm access (Android only, no-op elsewhere)
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestExactAlarmsPermission();
    return granted ?? false;
  }



  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? categoryIdentifier,
  }) async {
    final channelId = (id == 200 || id == 201) ? 'pomodoro' : 'subscription_expiry';
    final channelName = (id == 200 || id == 201) ? 'Pomodoro Timer' : 'Subscription Expiry';

    // 👇 only Pomodoro transitions need exact timing
    final isPomodoroTransition = id == 200 || id == 201;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: categoryIdentifier,
        ),
      ),
      androidScheduleMode: isPomodoroTransition
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
}