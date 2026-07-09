import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';

enum AppPickerMode { blockList, allowList }

// app with its category
class CategorizedApp {
  final AppInfo app;
  final String category;


  const CategorizedApp({
    required this.app,
    required this.category,
  });
}

@immutable
class AppPickerState {
  final Map<String, List<AppInfo>> categorizedApps;
  final List<AppInfo> searchResults;
  final List<String> selectedPackageNames;
  final bool isLoading;
  final bool isSearching;
  final String searchQuery;
  final AppPickerMode mode;
  final String? error;
  final List<AppInfo> allApps;

  const AppPickerState({
    this.allApps = const [],
    this.categorizedApps = const {},
    this.searchResults = const [],
    this.selectedPackageNames = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.mode = AppPickerMode.blockList,
    this.error,
  });

  int get selectedCount => selectedPackageNames.length;

  AppPickerState copyWith({
    List<AppInfo>? allApps,           // 👈 add this
    Map<String, List<AppInfo>>? categorizedApps,
    List<AppInfo>? searchResults,
    List<String>? selectedPackageNames,
    bool? isLoading,
    bool? isSearching,
    String? searchQuery,
    AppPickerMode? mode,
    String? error,
  }) {
    return AppPickerState(
      allApps: allApps ?? this.allApps, // 👈 add this
      categorizedApps: categorizedApps ?? this.categorizedApps,
      searchResults: searchResults ?? this.searchResults,
      selectedPackageNames:
      selectedPackageNames ?? this.selectedPackageNames,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      mode: mode ?? this.mode,
      error: error ?? this.error,
    );
  }
}