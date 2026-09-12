import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repository_providers.dart';
import 'app_colors.dart';

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, AccentColorOption>((ref) {
  return AccentColorNotifier(ref);
});

final darkAccentColorProvider = StateNotifierProvider<DarkAccentColorNotifier, DarkAccentOption>((ref) { // 👈 new
  return DarkAccentColorNotifier(ref);
});

class AccentColorNotifier extends StateNotifier<AccentColorOption> {
  final Ref ref;

  AccentColorNotifier(this.ref) : super(AccentColorOption.teal) {
    _load();
  }

  void _load() {
    final id = ref.read(settingsRepositoryProvider).getAccentColorId();
    final option = AccentColorOption.fromId(id);
    state = option;
    AppColors.selectedAccent = option;
  }

  Future<void> setAccent(AccentColorOption option) async {
    state = option;
    AppColors.selectedAccent = option;
    await ref.read(settingsRepositoryProvider).setAccentColorId(option.id);
  }
}

class DarkAccentColorNotifier extends StateNotifier<DarkAccentOption> { // 👈 new
  final Ref ref;

  DarkAccentColorNotifier(this.ref) : super(DarkAccentOption.warmGray) {
    _load();
  }

  void _load() {
    final id = ref.read(settingsRepositoryProvider).getDarkAccentColorId();
    final option = DarkAccentOption.fromId(id);
    state = option;
    AppColors.selectedDarkAccent = option;
  }

  Future<void> setAccent(DarkAccentOption option) async {
    state = option;
    AppColors.selectedDarkAccent = option;
    await ref.read(settingsRepositoryProvider).setDarkAccentColorId(option.id);
  }
}