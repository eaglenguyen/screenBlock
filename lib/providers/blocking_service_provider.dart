import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/platform/blocking_service.dart';
import '../domain/platform/ios_blocking_service.dart';
import '../domain/platform/stub_blocking_service.dart';
import '../domain/platform/android_blocking_service.dart';

final blockingServiceProvider = Provider<BlockingService>((ref) {
  const useStub = false;

  final service = useStub
      ? StubBlockingService()
      : Platform.isAndroid
      ? AndroidBlockingService()
      : Platform.isIOS
      ? IOSBlockingService()
      : throw UnsupportedError('Platform not supported');

  // reset overlay state on every provider creation
  service.resetOverlayState();

  ref.keepAlive();
  return service;
});