import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/constants/app_constants.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';
import '../../appPicker/app_picker_state.dart';
import '../../appPicker/app_picker_viewmodel.dart';

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
        color: Colors.white, // 👈 was AppColors.backgroundCard(context)
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context, title, subtitle, state),
          _buildSearchBar(context, state),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3B0))) // 👈 was AppColors.accent(context)
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
          color: const Color(0xFFF0E6D8), // 👈 was AppColors.border(context)
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
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF4A3728), fontSize: 22, fontWeight: FontWeight.w800), // 👈 was AppTextStyles.headlineSmall
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFB08A5A), fontSize: 12), // 👈 was AppTextStyles.bodySmall
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 👈 was 10/5
            decoration: BoxDecoration(
              color: const Color(0xFF7DD3B0).withValues(alpha: 0.15), // 👈 was AppColors.accent(context) alpha
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '${state.selectedCount}/50',
              style: const TextStyle( // 👈 was AppTextStyles.bodySmall
                color: Color(0xFF2D7A54), // 👈 was AppColors.accent(context)
                fontSize: 12,
                fontWeight: FontWeight.w700, // 👈 was w600
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
          color: const Color(0xFFFFF7ED), // 👈 was AppColors.backgroundSubtle(context)
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0E6D8), width: 0.5), // 👈 was AppColors.border(context)
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w600), // 👈 was AppTextStyles.bodyLarge
          onChanged: (q) => ref.read(appPickerViewModelProvider.notifier).search(q),
          decoration: InputDecoration(
            hintText: 'Search apps...',
            hintStyle: const TextStyle(color: Color(0xFFB08A5A)), // 👈 was AppTextStyles.bodyMedium
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB08A5A), size: 20), // 👈 was AppColors.textSecondary(context)
            suffixIcon: state.isSearching
                ? GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(appPickerViewModelProvider.notifier).clearSearch();
              },
              child: const Icon(Icons.close_rounded, color: Color(0xFFB08A5A), size: 18), // 👈 was AppColors.textSecondary(context)
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
      return const Center(
        child: Text('No apps found', style: TextStyle(color: Color(0xFFB08A5A))), // 👈 was AppTextStyles.bodyMedium
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
            style: const TextStyle( // 👈 was AppTextStyles.labelSmall
              color: Color(0xFFB08A5A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED), // 👈 was AppColors.backgroundSubtle(context)
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0E6D8), width: 0.5), // 👈 was AppColors.border(context)
          ),
          child: Column(
            children: List.generate(apps.length, (i) {
              final isLast = i == apps.length - 1;
              return Column(
                children: [
                  _appTile(context, apps[i], state),
                  if (!isLast)
                    const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0E6D8), indent: 56), // 👈 was AppColors.border(context)
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), // 👈 was 11
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: app.icon != null
                  ? Image.memory(app.icon!, width: 40, height: 40, fit: BoxFit.cover) // 👈 was 36
                  : Container(
                width: 40,
                height: 40,
                color: const Color(0xFFF0E6D8), // 👈 was AppColors.backgroundCard(context)
                child: const Icon(Icons.apps_rounded, color: Color(0xFFB08A5A), size: 20), // 👈 was AppColors.textSecondary(context)
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name ?? app.packageName ?? '',
                style: const TextStyle(color: Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w600), // 👈 was AppTextStyles.bodyLarge fontSize:14
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24, // 👈 was 22
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7DD3B0) : Colors.transparent, // 👈 was AppColors.accent(context)
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF7DD3B0) : const Color(0xFFF0E6D8), // 👈 was AppColors.accent/border
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Color(0xFF0F4A32), size: 16) // 👈 was AppColors.accentText(context), size:14
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
        color: Colors.white, // 👈 was AppColors.backgroundCard(context)
        border: Border(top: BorderSide(color: const Color(0xFFF0E6D8), width: 0.5)), // 👈 was AppColors.border(context)
      ),
      child: Column(
        children: [
          if (state.selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${state.selectedCount} APP${state.selectedCount == 1 ? '' : 'S'} SELECTED',
                style: const TextStyle( // 👈 was AppTextStyles.labelSmall
                  color: Color(0xFF2D7A54), // 👈 was AppColors.accent(context)
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isBlockList) {
                      final isPremium = ref.read(isPremiumProvider);
                      if (!isPremium && state.selectedCount > AppConstants.freeTrackedAppsLimit) {
                        Navigator.pop(context);
                        Future.microtask(() {
                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              useRootNavigator: true,
                              builder: (_) => const FeaturePaywallScreen(source: 'multiple_schedules'),
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
                    backgroundColor: const Color(0xFF7DD3B0), // 👈 was AppColors.accent(context)
                    foregroundColor: const Color(0xFF0F4A32), // 👈 was AppColors.accentText(context)
                    padding: const EdgeInsets.symmetric(vertical: 16), // 👈 was 15
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800), // 👈 was AppTextStyles.labelLarge
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A3728), // 👈 was AppColors.textPrimary(context)
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Color(0xFFF0E6D8)), // 👈 was AppColors.border(context)
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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