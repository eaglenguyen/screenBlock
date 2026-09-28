# Project State — 2026-09-18

Snapshot of where "pause now" (package `pausenow`, repo dir `screenblock`) stands right now. This is a point-in-time working-tree summary, not a replacement for `CLAUDE.md` (architecture) or `git log` (history).

## Branch & version

- Branch: `main`, clean history up to `0809e71` ("9/17 - Name changes").
- `pubspec.yaml` bumped to `2.0.4+135` (uncommitted) from `2.0.4+134`.
- **Rebrand in progress**: `android/app/src/main/AndroidManifest.xml` app label changed `"SpinBrek"` → `"Spinbrek"` (uncommitted). Note this is a display-label tweak only — bundle id is still `com.eagle.pausenow` and the Dart package is still `pausenow`; no wider rename has happened yet.

## Working tree — uncommitted changes

### New features mid-flight

- **Quick Block** (`lib/features/quickblock/`) — new `QuickBlockViewModel` + `QuickBlock` Hive model (`lib/data/models/quick_block.dart` / `.g.dart`). Generated `quick_block_viewmodel.g.dart` and `quick_block.g.dart` are untracked (need `git add`, and confirm they're current — run build_runner before committing).
- **Lock App** (`lib/features/lockapp/`) — `LockAppViewModel` + `LockAppConfig` Hive model, same situation: `.g.dart` files present but untracked.
- **Wheel** (`lib/UI/wheel/`) — `wheel_viewmodel.g.dart` untracked; `wheel_screen.dart` has a small modification.
- Reminder per `CLAUDE.md`: any touched `@riverpod`/`@HiveType` file needs `dart run build_runner build --delete-conflicting-outputs` re-run and the resulting `.g.dart` committed alongside its source before this is safe to land.

### Onboarding rework (`lib/onboarding_new/`)

Two new steps added to the flow (`onboarding_step_id.dart`, `onboarding_flow.dart`):
- `hobbies` → `OnboardingHobbiesScreen` (new file `gauntlet/screens/hobby_question.dart`, 558 lines, untracked/staged as `AM`). Has a `// 👈 add a matching field to your data model` TODO — `_data.hobbies` is wired into `onboarding_flow.dart` but needs the corresponding field added to `lib/onboarding_new/data/onboarding_data.dart` (that file only shows a 12-line diff so far — verify the `hobbies` field actually landed there).
- `demoComparison` → `OnboardingDemoComparisonScreen`, inserted after `commitmentSignature`. Also carries a `// 👈` TODO about `scheduleId` reuse vs. generation — needs a decision before shipping.
- New supporting screen: `lib/onboarding_new/screens/bar_graph.dart` (293 lines, new).
- Touched but smaller edits: `bad_news_screen.dart`, `good_news_screen.dart`, `graph_screen.dart`, `mutiple_schedule_mock.dart`, `permission_screen.dart`, `reassurance_screen.dart`, `widget/demo_video.dart` (62-line diff — largest of this group).
- `lib/onboarding/onboarding_question_bank.dart` (old onboarding flow) also has a 1-line change — check whether that's an intentional cross-edit or a stray change from search/replace.

### Home / schedule / paywall UI polish

- `lib/UI/home/timer/break_sheet.dart` — 73-line diff, largest of the home changes.
- `lib/UI/home/timer/timer_picker_sheet.dart`, `lib/UI/home/widgets/app_picker_sheet.dart`, `lib/UI/home/widgets/block_mode_sheet.dart` — smaller tweaks.
- `lib/UI/schedule/schedule_screen.dart` — 56-line diff; pairs with new **untracked** file `lib/UI/schedule/widgets/schedule_app_picker_sheet.dart` (a dedicated per-schedule app picker, gated by `isPremiumProvider`, free limit of 3 apps — mirrors `AppConstants.freeTrackedAppsLimit`).
- `lib/UI/schedule/widgets/session_mode_picker_sheet.dart` — small diff.
- `paywall/feature_paywall_screen.dart`, `paywall/onboarding_outlook_screen.dart`, `paywall/purchase_success_screen.dart` — each a 1–2 line change (likely copy/style tweaks, not logic).

### Constants

- `lib/core/constants/app_constants.dart` adds `focusSessionFreeAppsLimit = 1` (trailing `//` comment looks like an accidental leftover — worth cleaning before commit).

### Test scaffolding

- `?? test/` is untracked. Per `CLAUDE.md`, this directory is normally just unused counter-app boilerplate that doesn't compile against the app — confirm whether this is new real test setup or the same stale scaffold before committing.

## Not yet started / open questions

- No `.g.dart` regen has been confirmed for this session — run `dart run build_runner build --delete-conflicting-outputs` and check nothing else is stale beyond the four untracked generated files listed above.
- The Quick Block / Lock App features have no corresponding entry in `lib/providers/repository_providers.dart` mentioned in this diff — confirm wiring is complete (per `CLAUDE.md`, `BlockSessionRepository`-style repos with no interface are used directly, which may be intentional here too).
- Three-way state sync (Hive / SharedPreferences / native) — none of the diffed files touch `AndroidBlockingService` or the iOS App Group mirroring, so if Quick Block or Lock App introduce new session-relevant state, that sync is still outstanding.
- Rebrand: only the Android manifest label changed so far; iOS `Info.plist` display name, app store copy, and any in-app strings referencing "pause now" haven't been touched in this diff.

## Suggested next steps

1. Decide/resolve the two `// 👈` TODOs in `onboarding_flow.dart` (hobbies data field, demoComparison scheduleId).
2. Run build_runner, verify generated files match, `git add` the untracked `.g.dart` files.
3. Confirm `test/` is intentional before staging.
4. Clean the stray `//` comment on `focusSessionFreeAppsLimit`.
5. Decide on commit granularity — this is currently one large mixed diff (rebrand + 2 new features + onboarding rework + UI polish); consider splitting into logical commits.
