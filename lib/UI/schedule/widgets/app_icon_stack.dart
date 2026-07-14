import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class AppIconStack extends StatelessWidget {
  final List<String> packageNames; // Android: real package names
  final String? iosStorageKey; // iOS: e.g. 'timeLimitApps_<configId>' or 'schedule_<id>_<mode>'
  final double size;
  final Object? refreshToken; // 👈 new — pass anything that changes when apps change


  const AppIconStack({
    super.key,
    this.packageNames = const [],
    this.iosStorageKey,
    this.size = 40,
    this.refreshToken,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      if (iosStorageKey == null) return _placeholder(context);
      return SizedBox(
        width: size ,
        height: size ,
        child: UiKitView(
          key: ValueKey('$iosStorageKey-$refreshToken'), // 👈 new — forces recreation when data changes
          viewType: 'com.eagle.pausenow/app_icon_stack_view',
          creationParams: {
            'storageKey': iosStorageKey,
            'size': size,
          },
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }

    // Android
    if (packageNames.isEmpty) return _placeholder(context);

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.27),
            child: FutureBuilder<Uint8List?>(
              future: _fetchAppIcon(packageNames.first),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
                }
                return Container(
                  width: size,
                  height: size,
                  color: AppColors.backgroundSubtle(context),
                );
              },
            ),
          ),
          if (packageNames.length > 1)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundCard(context), width: 1.5),
                ),
                child: Text(
                  '+${packageNames.length - 1}',
                  style: TextStyle(
                    color: AppColors.goldText(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
    );
  }

  Future<Uint8List?> _fetchAppIcon(String packageName) async {
    try {
      return await const MethodChannel('com.eagle.pausenow/accessibility')
          .invokeMethod<Uint8List>('getAppIcon', {'packageName': packageName});
    } catch (_) {
      return null;
    }
  }
}