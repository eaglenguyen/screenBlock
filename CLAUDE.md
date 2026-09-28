# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"pause now" — a Flutter app-blocking / screen-time app for Android and iOS. Toolchain in use: Flutter 3.38.7, Dart 3.10.7.

The **directory is `screenblock` but the Dart package is `pausenow`**. All intra-project imports are `package:pausenow/...`; the bundle/application id is `com.eagle.pausenow`.

## Commands

```bash
flutter pub get
flutter run                      # attach a device; the app is device-only (no web/desktop)
flutter analyze                  # lints via flutter_lints; build/ and native dirs are excluded

# Code generation — required after touching any @riverpod class or @HiveType model
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs

flutter test                     # see caveat below
flutter test test/widget_test.dart -p "name of test"
```

`test/` contains only the untouched Flutter counter-app boilerplate, which does not compile against this app. There is no real test suite — do not treat `flutter test` as a green/red signal, and do not "fix" that file unless asked to build out testing.

Generated `*.g.dart` files **are committed**. Regenerate and commit them alongside their source.

## Architecture

### MVVM + Riverpod

Each feature is a triple: `<feature>_screen.dart` (ConsumerWidget), `<feature>_state.dart` (immutable state class with `copyWith`), `<feature>_viewmodel.dart` (`@riverpod class XViewModel extends _$XViewModel`, generating `<feature>_viewmodel.g.dart`).

Two parallel feature roots exist for historical reasons:
- `lib/UI/<feature>/` — home, schedule, stats, settings, appPicker, bottomNav
- `lib/featuress/<feature>/` — newer features (timelimit, wheel). The double-s spelling is the real directory name; keep it.

ViewModels commonly `ref.keepAlive()` and own long-lived `StreamSubscription`s/`Timer`s cancelled in `ref.onDispose`. `HomeViewModel` is the largest and drives the blocking session lifecycle via `HomeState.phase` (`BlockingPhase`: idle → countdown → active → onBreak → completed → claimXp).

### Data layer

Interfaces in `lib/data/repositories/` (`BlockingRepo.dart`, `ScheduleRepo.dart`, `SettingsRepo.dart`, `TimeLimitRepo.dart`), implementations in `lib/data/repositoryImpl/`, all wired in `lib/providers/repository_providers.dart` — that file is the single swap point for storage backends. `UsageStreakRepo`, `BlockSessionRepository` and `WheelRepoImpl` have no interface and are used directly.

Persistence is Hive, opened and adapter-registered up front in `main()`. Box names live in `core/constants/hivebox_names.dart`; **Hive `typeId`s are centralized in `core/constants/app_constants.dart`** — always allocate a new one there, never reuse a number.

### Three-way state duplication (the main source of bugs)

Blocking-session state is written to three places and they must be kept in sync:
1. **Hive** — durable app data (sessions, schedules, streaks, settings).
2. **Flutter `SharedPreferences`** — live session state (`isBlocking`, `monitoredApps`, `sessionStartTime`, …), written by `AndroidBlockingService.persistBlockingState()` and read back by `_restoreBlockingState()`.
3. **Native storage** — Android mirrors the same keys into native SharedPreferences (`saveBlockingState` channel call) so `AppBlockAccessibilityService` can enforce blocking while the Flutter engine is dead. iOS mirrors into the `group.com.eagle.pausenow` App Group so the Shield/Monitor extensions can read it.

If you change what a session records, update all three paths.

### Blocking abstraction

`lib/domain/blocking_service.dart` defines the `BlockingService` interface plus the `AppUsageEvent`/`AppEventType` stream contract. `providers/blocking_service_provider.dart` picks the implementation by `Platform`. The two implementations are structurally different, not just different bindings:

- **Android** (`domain/platform/android_blocking_service.dart`) — an `AccessibilityService` (`AppBlockAccessibilityService.kt`) reports foreground package changes over an EventChannel; Dart decides based on `_blockingMode` (`specific_apps` vs `all_apps`, see `AppConstants.blockingType*`) and asks native to launch `BlockActivity`. Requires usage-stats, overlay and accessibility permissions.
- **iOS** (`domain/platform/ios_blocking_service.dart`) — thin wrapper over Apple's FamilyControls / DeviceActivity / ManagedSettings in `ios/Runner/IOSBlockingService.swift`. Blocking is enforced by the OS shield; Dart mostly configures schedules and reads results. `IOSBlockingService.listenForNativeEvents` registers the callbacks native fires back (pause ended, session complete, notification actions, check-in flow).

Method/event channels (all prefixed `com.eagle.pausenow/`): `accessibility`, `block`, `foreground_app` (Android); `ios_blocking` (iOS, handled in `ios/Runner/AppDelegate.swift` — a large switch, the de-facto iOS API surface); plus platform-view channels `app_icon_stack_view`, `compact_screen_time_view`, `screen_time_report_view`, `weekly_data_trigger_view`.

`ScheduleChecker` (`lib/services/schedule_checker.dart`) is a singleton started from `MyApp.build()`; it polls every 5 s to activate/deactivate scheduled blocks and owns pause/resume accounting.

### iOS native layout

Real Xcode targets: `Runner`, `pausenowMonitor` (DeviceActivityMonitor), `ShieldActionExtension`, `ShieldConfigurationExtension`, `DeviceActivityReportExtension`, `PauseNowWidgetsExtension` (Live Activities). The directories `ios/ScreenBlockMonitor/` and `ios/DeviceActivityMonitorExtension/` are **not** in the project — stale copies; `ScreenBlockMonitor` even references the obsolete `group.com.eagle.screenblock` App Group. Edit the target dirs, not those.

### Routing & gating

`lib/app_router.dart` — go_router. A global `redirect` reads `onboardingComplete` from the Hive settings box and forces `/onboarding` until it is set. Tab screens live under a `ShellRoute` (`/home`, `/schedule`, `/stats`, `/settings`); `/onboarding` and `/paywall` sit outside the shell.

### Premium

RevenueCat, initialized in `main()`. The entitlement identifier is the literal string `'pause now Premium'`. Use `isPremiumProvider` for gating — note it returns the mutable `debugPremiumOverride` flag in debug builds, and premium status is pushed to iOS native via `setPremiumStatus` from a `ref.listen` in `MyApp`.

### Analytics

PostHog, configured in `main()` (project key is inline there). Go through `AnalyticsService.instance`; event/property names belong in `core/analytics/analytics_events.dart`. `captureOnce` dedupes via a Hive flag.

## Conventions

- Theme values come from `core/theme/` (`AppColors`, `AppTextStyles`, `AppTheme`); the app ships light and dark and `themeProvider` drives `themeMode` — don't hardcode colors.
- Repository files use PascalCase filenames (`BlockingRepo.dart`); models, viewmodels and widgets use snake_case. Match the folder you're in.
- The codebase logs liberally with emoji-prefixed `debugPrint` (`✅ 💾 ❌ 🟢`) and marks recent edits with `// 👈` comments.
