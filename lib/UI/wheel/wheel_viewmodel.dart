import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/hivebox_names.dart';
import '../../data/repositoryImpl/WheelRepoImpl.dart';
import 'wheel_state.dart';

part 'wheel_viewmodel.g.dart';

final wheelRepositoryProvider = Provider((ref) => WheelRepository());

const _commitModeKey = 'wheelCommitModeEnabled';
const _spinsUsedKey = 'wheelSpinsUsed';
const _cooldownEndsAtKey = 'wheelCooldownEndsAt'; // stored as millisecondsSinceEpoch
const _listNameKey = 'wheelListName'; // 👈 new

@riverpod
class WheelViewModel extends _$WheelViewModel {
  WheelRepository get _repo => ref.read(wheelRepositoryProvider);
  Box get _settingsBox => Hive.box(HiveBoxNames.settings);

  @override
  WheelState build() {
    final commitModeEnabled = _settingsBox.get(_commitModeKey, defaultValue: false) as bool;
    final spinsUsed = _settingsBox.get(_spinsUsedKey, defaultValue: 0) as int;
    final cooldownMillis = _settingsBox.get(_cooldownEndsAtKey) as int?;
    final cooldownEndsAt = cooldownMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(cooldownMillis)
        : null;
    final listName = _settingsBox.get(_listNameKey, defaultValue: 'Entries') as String; // 👈 new

    var initial = WheelState(
      items: _repo.getItems(),
      commitModeEnabled: commitModeEnabled,
      spinsUsed: spinsUsed,
      cooldownEndsAt: cooldownEndsAt,
      listName: listName, // 👈 new
    );

    if (initial.cooldownEndsAt != null && !initial.isInCooldown) {
      initial = initial.copyWith(spinsUsed: 0, clearCooldown: true);
      _persistSpinState(spinsUsed: 0, cooldownEndsAt: null);
    }

    return initial;
  }

  // 👇 new
  Future<void> setListName(String name) async {
    final trimmed = name.trim();
    final finalName = trimmed.isEmpty ? 'Entries' : trimmed;
    state = state.copyWith(listName: finalName);
    await _settingsBox.put(_listNameKey, finalName);
  }

  Future<void> addItem(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final updated = [...state.items, trimmed];
    state = state.copyWith(items: updated);
    await _repo.saveItems(updated);
  }

  Future<void> removeItem(String text) async {
    final updated = state.items.where((i) => i != text).toList();
    state = state.copyWith(items: updated);
    await _repo.saveItems(updated);
  }

  Future<void> addPresetList(List<String> presets) async {
    final merged = {...state.items, ...presets}.toList();
    state = state.copyWith(items: merged);
    await _repo.saveItems(merged);
  }

  void setSpinning(bool spinning) {
    state = state.copyWith(isSpinning: spinning);
  }

  void setResult(String result) {
    state = state.copyWith(lastResult: result, isSpinning: false);
  }

  void clearResult() {
    state = state.copyWith(clearLastResult: true);
  }

  // 👇 new — toggles Commit Mode on/off, persisted
  Future<void> toggleCommitMode() async {
    final next = !state.commitModeEnabled;
    state = state.copyWith(commitModeEnabled: next);
    await _settingsBox.put(_commitModeKey, next);
    // turning it off clears any active cooldown/spin count, so it doesn't linger if re-enabled later
    if (!next) {
      state = state.copyWith(spinsUsed: 0, clearCooldown: true);
      await _persistSpinState(spinsUsed: 0, cooldownEndsAt: null);
    }
  }

  // 👇 new — call this right after a spin completes (in WheelScreen's _spin() callback)
  Future<void> recordSpin() async {
    if (!state.commitModeEnabled) return;

    final newSpinsUsed = state.spinsUsed + 1;
    if (newSpinsUsed >= WheelState.maxSpinsBeforeCooldown) {
      final cooldownEndsAt = DateTime.now().add(WheelState.cooldownDuration);
      state = state.copyWith(spinsUsed: newSpinsUsed, cooldownEndsAt: cooldownEndsAt);
      await _persistSpinState(spinsUsed: newSpinsUsed, cooldownEndsAt: cooldownEndsAt);
    } else {
      state = state.copyWith(spinsUsed: newSpinsUsed);
      await _persistSpinState(spinsUsed: newSpinsUsed, cooldownEndsAt: null);
    }
  }

  // 👇 new — called periodically by the UI to check if a cooldown has just expired
  void checkCooldownExpiry() {
    if (state.cooldownEndsAt != null && !state.isInCooldown) {
      state = state.copyWith(spinsUsed: 0, clearCooldown: true);
      _persistSpinState(spinsUsed: 0, cooldownEndsAt: null);
    }
  }

  Future<void> _persistSpinState({required int spinsUsed, DateTime? cooldownEndsAt}) async {
    await _settingsBox.put(_spinsUsedKey, spinsUsed);
    if (cooldownEndsAt == null) {
      await _settingsBox.delete(_cooldownEndsAtKey);
    } else {
      await _settingsBox.put(_cooldownEndsAtKey, cooldownEndsAt.millisecondsSinceEpoch);
    }
  }
}