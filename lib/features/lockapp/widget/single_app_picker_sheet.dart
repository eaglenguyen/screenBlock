// lib/features/lockapp/widget/single_app_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import '../../../UI/appPicker/app_picker_state.dart';
import '../../../UI/appPicker/app_picker_viewmodel.dart';

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
        color: Colors.white, // 👈 was AppColors.backgroundCard(context)
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
                color: const Color(0xFFF0E6D8), // 👈 was AppColors.border(context)
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose an app',
                style: TextStyle( // 👈 was AppTextStyles.headlineSmall
                  color: const Color(0xFF4A3728),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
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
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3B0))) // 👈 was AppColors.accent(context)
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
      return const Center(
        child: Text('No apps found', style: TextStyle(color: Color(0xFFB08A5A))), // 👈 was AppTextStyles.bodyMedium
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
                      _tile(context, apps[i]),
                      if (!isLast) const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0E6D8), indent: 56), // 👈 was AppColors.border(context)
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB08A5A), size: 22), // 👈 was AppColors.textSecondary(context), size:20
          ],
        ),
      ),
    );
  }
}