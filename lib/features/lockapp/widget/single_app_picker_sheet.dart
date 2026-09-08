// lib/features/lockapp/widget/single_app_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import '../../../UI/appPicker/app_picker_state.dart';
import '../../../UI/appPicker/app_picker_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class SingleAppPickerSheet extends ConsumerStatefulWidget {
  final void Function(String packageName, String appName) onSelected;

  const SingleAppPickerSheet({super.key, required this.onSelected});

  @override
  ConsumerState<SingleAppPickerSheet> createState() => _SingleAppPickerSheetState();
}

class _SingleAppPickerSheetState extends ConsumerState<SingleAppPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(appPickerViewModelProvider.notifier);
      if (ref.read(appPickerViewModelProvider).allApps.isEmpty) {
        notifier.loadApps();
      }
      notifier.init(mode: AppPickerMode.blockList, preSelected: const []);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pick(AppInfo app) {
    final packageName = app.packageName ?? '';
    final appName = app.name ?? packageName;
    if (packageName.isEmpty) return;
    widget.onSelected(packageName, appName);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appPickerViewModelProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose an app', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context)),
                onChanged: (q) => ref.read(appPickerViewModelProvider.notifier).search(q),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary(context), size: 20),
                  suffixIcon: state.isSearching
                      ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      ref.read(appPickerViewModelProvider.notifier).clearSearch();
                    },
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 18),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.accent(context)))
                : state.isSearching
                ? _list(context, state.searchResults)
                : _categorized(context, state),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<AppInfo> apps) {
    if (apps.isEmpty) {
      return Center(
        child: Text('No apps found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: apps.length,
      itemBuilder: (context, index) => _tile(context, apps[index]),
    );
  }

  Widget _categorized(BuildContext context, AppPickerState state) {
    final categories = state.categorizedApps.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final label = categories[index].key;
        final apps = categories[index].value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary(context), letterSpacing: 0.12),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: Column(
                children: List.generate(apps.length, (i) {
                  final isLast = i == apps.length - 1;
                  return Column(
                    children: [
                      _tile(context, apps[i]),
                      if (!isLast) Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 56),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, AppInfo app) {
    return InkWell(
      onTap: () => _pick(app),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: app.icon != null
                  ? Image.memory(app.icon!, width: 36, height: 36, fit: BoxFit.cover)
                  : Container(
                width: 36,
                height: 36,
                color: AppColors.backgroundCard(context),
                child: Icon(Icons.apps_rounded, color: AppColors.textSecondary(context), size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name ?? app.packageName ?? '',
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 14, color: AppColors.textPrimary(context)),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
          ],
        ),
      ),
    );
  }
}