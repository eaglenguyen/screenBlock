import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/core/constants/hivebox_names.dart';
import 'package:pausenow/onboarding_new/old_onboarding/onboarding_state.dart';
import 'package:pausenow/onboarding_new/old_onboarding/onboarding_viewmodel.dart';
import 'package:pausenow/providers/blocking_service_provider.dart';

import '../support/fake_blocking_service.dart';

// These tests exercise OnboardingViewModel's navigation and persistence
// logic directly, independent of whatever the chat/personalization/pricing
// screens end up looking like after the redesign. If a rewritten screen
// still calls setDailyScreenTime('3–4 hours') or completeOnboarding(), this
// suite guarantees the underlying state and Hive writes are still correct.
void main() {
  late Directory tempDir;
  late FakeBlockingService fakeService;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onboarding_vm_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxNames.settings);

    fakeService = FakeBlockingService();
    container = ProviderContainer(
      overrides: [
        blockingServiceProvider.overrideWithValue(fakeService),
      ],
    );
    // OnboardingViewModel is @riverpod (autoDispose) with no ref.keepAlive(),
    // same as it runs in the app: a screen widget's ref.watch keeps it alive
    // for the whole flow. Without a listener here it would dispose between
    // our reads and silently reset in-memory state (isComplete, etc.) even
    // though its Hive writes stick around — mirror that with a keep-alive.
    container.listen(onboardingViewModelProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    fakeService.dispose();
    await Hive.deleteBoxFromDisk(HiveBoxNames.settings);
    await tempDir.delete(recursive: true);
  });

  OnboardingViewModel vm() =>
      container.read(onboardingViewModelProvider.notifier);

  group('build', () {
    test('starts with no userName when Hive has none saved', () {
      final state = container.read(onboardingViewModelProvider);
      expect(state.userName, isNull);
      expect(state.currentStep, OnboardingStep.chat);
    });

    test('restores a previously saved userName', () {
      Hive.box(HiveBoxNames.settings).put('userName', 'Riley');
      // fresh container so build() re-reads the box
      final freshContainer = ProviderContainer(
        overrides: [blockingServiceProvider.overrideWithValue(fakeService)],
      );
      freshContainer.listen(onboardingViewModelProvider, (_, _) {});
      addTearDown(freshContainer.dispose);

      final state = freshContainer.read(onboardingViewModelProvider);
      expect(state.userName, 'Riley');
    });
  });

  group('navigation', () {
    test('goToStep updates currentStep and nothing else', () {
      vm().setUserName('Riley');
      vm().goToStep(OnboardingStep.pricing);

      final state = container.read(onboardingViewModelProvider);
      expect(state.currentStep, OnboardingStep.pricing);
      expect(state.userName, 'Riley');
    });
  });

  group('setUserName', () {
    test('trims whitespace and persists immediately to Hive', () {
      vm().setUserName('  Riley  ');

      expect(container.read(onboardingViewModelProvider).userName, 'Riley');
      expect(Hive.box(HiveBoxNames.settings).get('userName'), 'Riley');
    });
  });

  group('setDailyScreenTime', () {
    const expectedHours = {
      'Less than 1 hour': 0.5,
      '1–2 hours': 1.5,
      '2–3 hours': 2.5,
      '3–4 hours': 3.5,
      '4–5 hours': 4.5,
      '5–6 hours': 5.5,
      '6–7 hours': 6.5,
      '7+ hours': 8.0,
    };

    expectedHours.forEach((range, hours) {
      test('"$range" maps to $hours dailyHours', () {
        vm().setDailyScreenTime(range);
        final state = container.read(onboardingViewModelProvider);
        expect(state.dailyScreenTime, range);
        expect(state.dailyHours, hours);
      });
    });

    test('an unrecognized range falls back to 3.5 hours', () {
      vm().setDailyScreenTime('literally who knows');
      expect(
        container.read(onboardingViewModelProvider).dailyHours,
        3.5,
      );
    });
  });

  group('permissions', () {
    test('recheckPermissions reflects the platform service state', () async {
      fakeService.usageStatsGranted = true;
      fakeService.overlayGranted = false;
      fakeService.accessibilityGranted = true;

      await vm().recheckPermissions();

      final state = container.read(onboardingViewModelProvider);
      expect(state.hasUsagePermission, isTrue);
      expect(state.hasOverlayPermission, isFalse);
      expect(state.hasAccessibilityPermission, isTrue);
      expect(state.permissionsGranted, 2);
      expect(state.allPermissionsGranted, isFalse);
    });

    test('requestUsagePermission requests then re-syncs state', () async {
      expect(fakeService.usageStatsGranted, isFalse);

      await vm().requestUsagePermission();

      expect(fakeService.calls, contains('requestUsageStatsPermission'));
      expect(
        container.read(onboardingViewModelProvider).hasUsagePermission,
        isTrue,
      );
    });

    test('requesting all three permissions satisfies allPermissionsGranted', () async {
      await vm().requestUsagePermission();
      await vm().requestOverlayPermission();
      await vm().requestAccessibilityPermission();

      expect(
        container.read(onboardingViewModelProvider).allPermissionsGranted,
        isTrue,
      );
    });
  });

  group('persistence', () {
    test('savePersonalizationData writes every field, defaulting unset ones', () async {
      vm().setUserName('Riley');
      vm().setGoal('Read more');
      // dailyScreenTime/mainStruggle/hearAboutUs deliberately left unset

      await vm().savePersonalizationData();

      final box = Hive.box(HiveBoxNames.settings);
      expect(box.get('userName'), 'Riley');
      expect(box.get('goal'), 'Read more');
      expect(box.get('dailyScreenTime'), '');
      expect(box.get('dailyHours'), 3.5);
      expect(box.get('mainStruggle'), '');
      expect(box.get('hearAboutUs'), '');
    });

    test('completeOnboarding saves data, flips the Hive flag, and marks state complete', () async {
      expect(OnboardingViewModel.isOnboardingComplete(), isFalse);

      vm().setUserName('Riley');
      await vm().completeOnboarding();

      expect(OnboardingViewModel.isOnboardingComplete(), isTrue);
      expect(container.read(onboardingViewModelProvider).isComplete, isTrue);
      expect(Hive.box(HiveBoxNames.settings).get('userName'), 'Riley');
    });
  });
}
