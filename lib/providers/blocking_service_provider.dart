import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/blocking_service.dart';
import '../domain/platform/ios_blocking_service.dart';
import '../domain/platform/android_blocking_service.dart';

final blockingServiceProvider = Provider<BlockingService>((ref) {
  final service = Platform.isAndroid
      ? AndroidBlockingService()
      : Platform.isIOS
      ? IOSBlockingService()
      : throw UnsupportedError('Platform not supported');

  service.resetOverlayState();

  ref.keepAlive();
  return service;
});