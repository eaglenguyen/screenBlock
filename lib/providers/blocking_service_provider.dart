import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/platform/blocking_service.dart';
import '../domain/platform/stub_blocking_service.dart';
import '../domain/platform/android_blocking_service.dart';

final blockingServiceProvider = Provider<BlockingService>((ref) {
  // swap this flag to false when Android
  // implementation is ready
  const useStub = true;

  if (useStub) return StubBlockingService();
  if (Platform.isAndroid) return AndroidBlockingService();

  throw UnsupportedError('Platform not supported');
});