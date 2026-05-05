import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_picker_state.dart';

part 'app_picker_viewmodel.g.dart';

@riverpod
class AppPickerViewModel extends _$AppPickerViewModel {

  @override
  AppPickerState build() {
    loadApps();
    return const AppPickerState(isLoading: true);
  }

  // ── Load installed apps ─────────────────────────
  Future<void> loadApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );

      // sort alphabetically
      apps.sort((a, b) =>
          (a.name ?? '').compareTo(b.name ?? ''));

      state = state.copyWith(
        allApps: apps,
        filteredApps: apps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Search ──────────────────────────────────────
  void search(String query) {
    final filtered = state.allApps.where((app) {
      return (app.name ?? '')
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(
      searchQuery: query,
      filteredApps: filtered,
    );
  }

  // ── Selection ───────────────────────────────────
  void toggleSelection(String packageName) {
    final selected = List<String>.from(state.selectedPackageNames);

    if (selected.contains(packageName)) {
      selected.remove(packageName);
    } else {
      selected.add(packageName);
    }

    state = state.copyWith(selectedPackageNames: selected);
  }

  bool isSelected(String packageName) {
    return state.selectedPackageNames.contains(packageName);
  }

  void clearSelection() {
    state = state.copyWith(selectedPackageNames: []);
  }
}