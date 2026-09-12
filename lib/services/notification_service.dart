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
    await androidPlugin?.createNotificationChannel( // 👈 new — dedicated channel
      const AndroidNotificationChannel(
        'session_complete',
        'Session Complete',
        description: 'Notifies when a focus session finishes',
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
    final channelId = switch (id) { // 👈 was a two-way ternary — now explicit per-ID routing
      200 || 201 => 'pomodoro',
      202 => 'session_complete', // 👈 new — was falling into subscription_expiry
      _ => 'subscription_expiry',
    };
    final channelName = switch (id) {
      200 || 201 => 'Pomodoro Timer',
      202 => 'Session Complete',
      _ => 'Subscription Expiry',
    };

    final isTimeCritical = id == 200 || id == 201 || id == 202; // 👈 was isPomodoroTransition — now includes 202

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
      androidScheduleMode: isTimeCritical
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