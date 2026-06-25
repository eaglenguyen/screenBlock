import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/premium_provider.dart';
import '../../appPicker/app_picker_state.dart';
import '../../appPicker/app_picker_viewmodel.dart';
import '../../paywall/feature_paywall_screen.dart';

class AppListSheet extends ConsumerStatefulWidget {
  const AppListSheet({
    super.key,
    required this.isBlockList,
    required this.initialApps,
    required this.onSave,
  });

  final bool isBlockList;
  final List<String> initialApps;
  final ValueChanged<List<String>> onSave;

  @override
  ConsumerState<AppListSheet> createState() => _AppListSheetState();
}

class _AppListSheetState extends ConsumerState<AppListSheet> {

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(appPickerViewModelProvider.notifier);
      if (ref.read(appPickerViewModelProvider).allApps.isEmpty) {
        notifier.loadApps();
      }
      notifier.init(
        mode: widget.isBlockList ? AppPickerMode.blockList : AppPickerMode.allowList,
        preSelected: widget.initialApps,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appPickerViewModelProvider);
    final title = widget.isBlockList ? 'Blocked Apps' : 'Allowed Apps';
    final subtitle = widget.isBlockList
        ? 'These apps will remain blocked during sessions'
        : 'These apps will remain unblocked during sessions';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context, title, subtitle, state),
          _buildSearchBar(context, state),
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.gold(context)))
                : state.isSearching
                ? _buildSearchResults(context, state)
                : _buildCategorizedList(context, state),
          ),
          _buildBottom(context, state),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, String subtitle, AppPickerState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '${state.selectedCount}/50',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gold(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppPickerState state) {
    return Padding(
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
    );
  }

  Widget _buildSearchResults(BuildContext context, AppPickerState state) {
    if (state.searchResults.isEmpty) {
      return Center(
        child: Text('No apps found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) => _appTile(context, state.searchResults[index], state),
    );
  }

  Widget _buildCategorizedList(BuildContext context, AppPickerState state) {
    final categories = state.categorizedApps.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) => _buildCategory(context, categories[index].key, categories[index].value, state),
    );
  }

  Widget _buildCategory(BuildContext context, String label, List<AppInfo> apps, AppPickerState state) {
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
                  _appTile(context, apps[i], state),
                  if (!isLast)
                    Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 56),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _appTile(BuildContext context, AppInfo app, AppPickerState state) {
    final isSelected = ref.read(appPickerViewModelProvider.notifier).isSelected(app.packageName ?? '');

    return InkWell(
      onTap: () => ref.read(appPickerViewModelProvider.notifier).toggleApp(app.packageName ?? ''),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold(context) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.gold(context) : AppColors.border(context),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: AppColors.goldText(context), size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(BuildContext context, AppPickerState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        border: Border(top: BorderSide(color: AppColors.border(context), width: 0.5)),
      ),
      child: Column(
        children: [
          if (state.selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${state.selectedCount} APP${state.selectedCount == 1 ? '' : 'S'} SELECTED',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.gold(context), letterSpacing: 0.1),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // check free limit only for block list mode
                    if (widget.isBlockList) {
                      final isPremium = ref.read(isPremiumProvider);
                      if (!isPremium && state.selectedCount > AppConstants.freeTrackedAppsLimit) {
                        // close sheet first then push paywall
                        Navigator.pop(context);
                        Future.microtask(() {
                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              useRootNavigator: true,
                              builder: (_) => const FeaturePaywallScreen(),
                            );
                          }
                        });
                        return;
                      }
                    }
                    widget.onSave(state.selectedPackageNames);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold(context),
                    foregroundColor: AppColors.goldText(context),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppColors.border(context)),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}