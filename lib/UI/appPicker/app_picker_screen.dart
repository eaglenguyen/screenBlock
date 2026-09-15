import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
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
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
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
      decoration: BoxDecoration(
        color: Colors.white, // 👈 was AppColors.backgroundCard(context)
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildSearchBar(state),
          Expanded(
            child: state.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7DD3B0)), // 👈 was AppColors.accent(context)
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
          color: const Color(0xFFF0E6D8), // 👈 was AppColors.border(context)
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

  Widget _buildSearchResults(AppPickerState state) {
    if (state.searchResults.isEmpty) {
      return const Center(
        child: Text('No apps found', style: TextStyle(color: Color(0xFFB08A5A))), // 👈 was AppTextStyles.bodyMedium
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

  Widget _buildCategorizedList(AppPickerState state) {
    final categories = state.categorizedApps.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategory(category.key, category.value, state);
      },
    );
  }

  Widget _buildCategory(String label, List<AppInfo> apps, AppPickerState state) {
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
              final app = apps[i];
              final isLast = i == apps.length - 1;
              return Column(
                children: [
                  _appTile(app, state),
                  if (!isLast)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: Color(0xFFF0E6D8), // 👈 was AppColors.border(context)
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
    final isSelected = ref.read(appPickerViewModelProvider.notifier).isSelected(app.packageName ?? '');

    return InkWell(
      onTap: () => ref.read(appPickerViewModelProvider.notifier).toggleApp(app.packageName ?? ''),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), // 👈 was 11 — a bit taller
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

  Widget _buildBottom(AppPickerState state) {
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