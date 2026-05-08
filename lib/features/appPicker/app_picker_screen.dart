import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'app_picker_state.dart';
import 'app_picker_viewmodel.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({
    super.key,
    required this.mode,
    required this.preSelected,
    required this.onSave,
  });

  final AppPickerMode mode;
  final List<String> preSelected;
  final ValueChanged<List<String>> onSave;

  @override
  ConsumerState<AppPickerScreen> createState() =>
      _AppPickerScreenState();
}

class _AppPickerScreenState
    extends ConsumerState<AppPickerScreen> {

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appPickerViewModelProvider.notifier).init(
        mode: widget.mode,
        preSelected: widget.preSelected,
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildSearchBar(state),
          Expanded(
            child: state.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            )
                : state.isSearching
                ? _buildSearchResults(state)
                : _buildCategorizedList(state),
          ),
          _buildBottom(state),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppPickerState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyLarge,
          onChanged: (q) => ref
              .read(appPickerViewModelProvider.notifier)
              .search(q),
          decoration: InputDecoration(
            hintText: 'Search apps...',
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: state.isSearching
                ? GestureDetector(
              onTap: () {
                _searchController.clear();
                ref
                    .read(appPickerViewModelProvider
                    .notifier)
                    .clearSearch();
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Search results ───────────────────────────────
  Widget _buildSearchResults(AppPickerState state) {
    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          'No apps found',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final app = state.searchResults[index];
        return _appTile(app, state);
      },
    );
  }

  // ── Categorized list ─────────────────────────────
  Widget _buildCategorizedList(AppPickerState state) {
    final categories = state.categorizedApps.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategory(
          category.key,
          category.value,
          state,
        );
      },
    );
  }

  Widget _buildCategory(
      String label,
      List<AppInfo> apps,
      AppPickerState state,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.12,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(apps.length, (i) {
              final app = apps[i];
              final isLast = i == apps.length - 1;
              return Column(
                children: [
                  _appTile(app, state),
                  if (!isLast)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border,
                      indent: 56,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _appTile(AppInfo app, AppPickerState state) {
    final isSelected =
    ref.read(appPickerViewModelProvider.notifier)
        .isSelected(app.packageName ?? '');

    return InkWell(
      onTap: () => ref
          .read(appPickerViewModelProvider.notifier)
          .toggleApp(app.packageName ?? ''),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 11,
        ),
        child: Row(
          children: [
            // app icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: app.icon != null
                  ? Image.memory(
                app.icon!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 36,
                height: 36,
                color: AppColors.backgroundCard,
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name ?? app.packageName ?? '',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 14,
                ),
              ),
            ),
            // checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check_rounded,
                color: AppColors.goldText,
                size: 14,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────
  Widget _buildBottom(AppPickerState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          if (state.selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${state.selectedCount} APP${state.selectedCount == 1 ? '' : 'S'} SELECTED',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(
                      state.selectedPackageNames,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
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
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: const StadiumBorder(),
                    side: const BorderSide(
                      color: AppColors.border,
                    ),
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