import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositoryImpl/WheelRepoImpl.dart';
import 'wheel_state.dart';

part 'wheel_viewmodel.g.dart';

final wheelRepositoryProvider = Provider((ref) => WheelRepository());

@riverpod
class WheelViewModel extends _$WheelViewModel {
  WheelRepository get _repo => ref.read(wheelRepositoryProvider);

  @override
  WheelState build() {
    return WheelState(items: _repo.getItems());
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
    final merged = {...state.items, ...presets}.toList(); // dedupe
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
}