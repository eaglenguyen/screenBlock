import 'package:flutter_test/flutter_test.dart';
import 'package:pausenow/onboarding_new/old_onboarding/onboarding_state.dart';

// These calculated getters feed the "you'll waste N days a year" style
// copy on the onboarding calculation/pricing screens. They have no
// dependency on layout, so they should keep passing across the visual
// revamp — if one of these breaks, the numbers shown to the user are wrong
// even if the screen looks perfect.
void main() {
  group('OnboardingState calculated stats', () {
    test('default state has zeroed-out stats', () {
      const state = OnboardingState();
      expect(state.dailyHours, isNull);
      expect(state.monthlyHours, 0);
      expect(state.yearlyHours, 0);
      expect(state.daysPerYear, 0);
    });

    test('monthlyHours/yearlyHours/daysPerYear derive from dailyHours', () {
      const state = OnboardingState(dailyHours: 4.0);
      expect(state.monthlyHours, 120); // 4 * 30
      expect(state.yearlyHours, 1460); // 4 * 365
      expect(state.daysPerYear, closeTo(60.83, 0.01)); // 1460 / 24
    });

    group('formattedDailyHours', () {
      test('renders sub-hour values in minutes', () {
        const state = OnboardingState(dailyHours: 0.5);
        expect(state.formattedDailyHours, '30 minutes');
      });

      test('renders whole hours without a decimal', () {
        const state = OnboardingState(dailyHours: 3.0);
        expect(state.formattedDailyHours, '3 hours');
      });

      test('renders fractional hours with the decimal kept', () {
        const state = OnboardingState(dailyHours: 3.5);
        expect(state.formattedDailyHours, '3.5 hours');
      });

      test('treats a missing dailyHours as zero', () {
        const state = OnboardingState();
        expect(state.formattedDailyHours, '0 minutes');
      });
    });

    test('formattedMonthlyHours rounds to a whole number', () {
      const state = OnboardingState(dailyHours: 2.5); // 75 hours/month
      expect(state.formattedMonthlyHours, '75 hours');
    });

    test('formattedDaysPerYear keeps one decimal place', () {
      const state = OnboardingState(dailyHours: 4.0);
      expect(state.formattedDaysPerYear, '60.8');
    });
  });

  group('OnboardingState permissions', () {
    test('allPermissionsGranted is false until all three are true', () {
      const none = OnboardingState();
      const partial = OnboardingState(
        hasUsagePermission: true,
        hasOverlayPermission: true,
      );
      const all = OnboardingState(
        hasUsagePermission: true,
        hasOverlayPermission: true,
        hasAccessibilityPermission: true,
      );

      expect(none.allPermissionsGranted, isFalse);
      expect(partial.allPermissionsGranted, isFalse);
      expect(all.allPermissionsGranted, isTrue);
    });

    test('permissionsGranted counts how many are true', () {
      const state = OnboardingState(
        hasUsagePermission: true,
        hasAccessibilityPermission: true,
      );
      expect(state.permissionsGranted, 2);
    });
  });

  group('OnboardingState.copyWith', () {
    test('overrides only the fields passed in', () {
      const original = OnboardingState(
        currentStep: OnboardingStep.chat,
        userName: 'Alex',
        goal: 'Focus more',
      );

      final updated = original.copyWith(currentStep: OnboardingStep.pricing);

      expect(updated.currentStep, OnboardingStep.pricing);
      expect(updated.userName, 'Alex'); // unrelated fields untouched
      expect(updated.goal, 'Focus more');
    });

    test('does not clear a previously-set field when omitted', () {
      const original = OnboardingState(userName: 'Alex');
      final updated = original.copyWith(goal: 'Sleep better');

      // known copyWith footgun: passing null does NOT clear a field,
      // it falls back to `this.field` — worth locking in explicitly.
      expect(updated.userName, 'Alex');
      expect(updated.goal, 'Sleep better');
    });
  });
}
