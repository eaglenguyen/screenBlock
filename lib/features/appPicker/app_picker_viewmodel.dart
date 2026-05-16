import 'package:flutter/cupertino.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_picker_state.dart';

part 'app_picker_viewmodel.g.dart';

// categories mapped from common package name patterns
const Map<String, List<String>> _categoryPatterns = {
  'Social': [
    'instagram', 'facebook', 'twitter', 'tiktok',
    'snapchat', 'whatsapp', 'telegram', 'discord',
    'linkedin', 'pinterest', 'reddit', 'tumblr',
  ],
  'Entertainment': [
    'youtube', 'netflix', 'spotify', 'twitch',
    'hulu', 'disneyplus', 'hbomax', 'tidal',
    'soundcloud', 'pandora', 'deezer',
  ],
  'Games': [
    'game', 'games', 'gaming', 'clash', 'candy',
    'pokemon', 'roblox', 'minecraft', 'fortnite',
  ],
  'Productivity': [
    'notion', 'slack', 'trello', 'asana', 'todoist',
    'calendar', 'docs', 'sheets', 'drive', 'office',
    'word', 'excel', 'zoom', 'meet', 'teams',
  ],
  'Shopping': [
    'amazon', 'ebay', 'etsy', 'walmart', 'target',
    'shein', 'wish', 'shopify', 'alibaba',
  ],
  'News': [
    'news', 'cnn', 'bbc', 'nytimes', 'reddit',
    'flipboard', 'feedly', 'medium',
  ],
};

@riverpod
class AppPickerViewModel extends _$AppPickerViewModel {

  @override
  AppPickerState build() {
    ref.keepAlive(); // 👈 prevents disposal between sheet opens
    return const AppPickerState(isLoading: true);
  }

  // ── Init with pre-selected apps ─────────────────
  void init({
    required AppPickerMode mode,
    required List<String> preSelected,
  }) {
    state = state.copyWith(
      mode: mode,
      selectedPackageNames: preSelected,
    );
  }

  // ── Load and categorize apps ────────────────────
  Future<void> loadApps() async {
    // skip if already loaded
    if (state.allApps.isNotEmpty) {
      debugPrint('🟡 apps already cached — skipping load');
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      final categorized = _categorizeApps(apps);
      state = state.copyWith(
        categorizedApps: categorized,
        isLoading: false,
        allApps: apps
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Map<String, List<AppInfo>> _categorizeApps(
      List<AppInfo> apps,
      ) {
    final Map<String, List<AppInfo>> result = {};

    for (final app in apps) {
      final category = _getCategory(app);
      result.putIfAbsent(category, () => []).add(app);
    }

    // sort categories alphabetically
    // but put 'Other' last
    final sorted = Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) {
          if (a.key == 'Other') return 1;
          if (b.key == 'Other') return -1;
          return a.key.compareTo(b.key);
        }),
    );

    return sorted;
  }

  String _getCategory(AppInfo app) {
    final packageName =
    (app.packageName ?? '').toLowerCase();
    final appName = (app.name ?? '').toLowerCase();

    for (final entry in _categoryPatterns.entries) {
      for (final keyword in entry.value) {
        if (packageName.contains(keyword) ||
            appName.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  // ── Search ──────────────────────────────────────
  void search(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        isSearching: false,
        searchResults: [],
      );
      return;
    }

    final allApps = state.categorizedApps.values
        .expand((apps) => apps)
        .toList();

    final results = allApps.where((app) {
      final name = (app.name ?? '').toLowerCase();
      final pkg = (app.packageName ?? '').toLowerCase();
      final q = query.toLowerCase();
      return name.contains(q) || pkg.contains(q);
    }).toList();

    state = state.copyWith(
      searchQuery: query,
      isSearching: true,
      searchResults: results,
    );
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      isSearching: false,
      searchResults: [],
    );
  }

  // ── Selection ───────────────────────────────────
  void toggleApp(String packageName) {
    final selected =
    List<String>.from(state.selectedPackageNames);

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
}
