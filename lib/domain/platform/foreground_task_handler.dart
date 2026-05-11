import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startForegroundCallback() {
  debugPrint('🟢 startForegroundCallback called');
  FlutterForegroundTask.setTaskHandler(AppMonitorTaskHandler());
}

class AppMonitorTaskHandler extends TaskHandler {
  String? _lastForegroundApp;
  Map<String, int> _monitoredApps = {};

  @override
  Future<void> onStart(
      DateTime timestamp,
      TaskStarter starter,
      ) async {
    debugPrint('🟢 task handler onStart called');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    debugPrint('🟢 onRepeatEvent tick');
    try {
      final now = DateTime.now();
      final usage = await AppUsage().getAppUsage(
        now.subtract(const Duration(seconds: 10)),
        now,
      );

      if (usage.isEmpty) {
        debugPrint('🟡 usage empty');
        return;
      }

      usage.sort((a, b) => b.usage.compareTo(a.usage));
      final foregroundApp = usage.first.packageName;

      debugPrint('🟡 foreground: $foregroundApp');
      debugPrint('🟡 monitoring: $_monitoredApps');

      if (foregroundApp == _lastForegroundApp) return;
      _lastForegroundApp = foregroundApp;

      if (_monitoredApps.containsKey(foregroundApp)) {
        debugPrint('🟢 monitored app detected: $foregroundApp — sending to main');
        FlutterForegroundTask.sendDataToMain(foregroundApp);
      }
    } catch (e) {
      debugPrint('❌ onRepeatEvent error: $e');
    }
  }

  @override
  Future<void> onDestroy(
      DateTime timestamp,
      bool isTimeout,
      ) async {
    debugPrint('🟢 task handler destroyed');
  }

  @override
  void onReceiveData(Object data) {
    debugPrint('🟢 onReceiveData: $data');
    if (data is Map) {
      _monitoredApps = Map<String, int>.from(data);
      debugPrint('🟢 now monitoring ${_monitoredApps.length} apps: $_monitoredApps');
    }
  }
}