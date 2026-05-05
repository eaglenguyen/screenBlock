import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';

@immutable
class AppPickerState {
  final List<AppInfo> allApps;
  final List<AppInfo> filteredApps;
  final List<String> selectedPackageNames;
  final bool isLoading;
  final String searchQuery;
  final String? error;

  const AppPickerState({
    this.allApps = const [],
    this.filteredApps = const [],
    this.selectedPackageNames = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
  });

  AppPickerState copyWith({
    List<AppInfo>? allApps,
    List<AppInfo>? filteredApps,
    List<String>? selectedPackageNames,
    bool? isLoading,
    String? searchQuery,
    String? error,
  }) {
    return AppPickerState(
      allApps: allApps ?? this.allApps,
      filteredApps: filteredApps ?? this.filteredApps,
      selectedPackageNames:
      selectedPackageNames ?? this.selectedPackageNames,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}