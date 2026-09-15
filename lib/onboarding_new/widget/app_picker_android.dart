import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import '../../UI/appPicker/app_picker_state.dart'; // adjust path to match your actual location
import '../../UI/appPicker/app_picker_viewmodel.dart'; // adjust path

class EmbeddedAndroidAppPicker extends ConsumerStatefulWidget {
  final List<String> preSelected;
  final ValueChanged<List<String>> onSelectionChanged;

  const EmbeddedAndroidAppPicker({
    super.key,
    required this.preSelected,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<EmbeddedAndroidAppPicker> createState() => _EmbeddedAndroidAppPickerState();
}

class _EmbeddedAndroidAppPickerState extends ConsumerState<EmbeddedAndroidAppPicker> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(appPickerViewModelProvider.notifier).init(
        mode: AppPickerMode.blockList,
        preSelected: widget.preSelected,
      );
      await ref.read(appPickerViewModelProvider.notifier).loadApps(); // 👈 new — actually fetches the installed app list
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectionChanged(state.selectedPackageNames);
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSearchBar(state),
          Expanded(
            child: state.isLoading
                ? _buildLoadingState() // 👈 new — was just a plain CircularProgressIndicator
                : state.isSearching
                ? _buildSearchResults(state)
                : _buildCategorizedList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() { // 👈 new
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF7DD3B0)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'If you have a lot of apps installed, this can take a minute — hang tight!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB08A5A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppPickerState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0E6D8), width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Color(0xFF4A3728), fontSize: 15),
          onChanged: (q) => ref.read(appPickerViewModelProvider.notifier).search(q),
          decoration: InputDecoration(
            hintText: 'Search apps...',
            hintStyle: const TextStyle(color: Color(0xFFB08A5A)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB08A5A), size: 20),
            suffixIcon: state.isSearching
                ? GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(appPickerViewModelProvider.notifier).clearSearch();
              },
              child: const Icon(Icons.close_rounded, color: Color(0xFFB08A5A), size: 18),
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
      return const Center(child: Text('No apps found', style: TextStyle(color: Color(0xFFB08A5A))));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) => _appTile(state.searchResults[index]),
    );
  }

  Widget _buildCategorizedList(AppPickerState state) {
    final categories = state.categorizedApps.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) => _buildCategory(categories[index].key, categories[index].value),
    );
  }

  Widget _buildCategory(String label, List<AppInfo> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(color: Color(0xFFB08A5A), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF0E6D8), width: 0.5),
          ),
          child: Column(
            children: List.generate(apps.length, (i) {
              final isLast = i == apps.length - 1;
              return Column(
                children: [
                  _appTile(apps[i]),
                  if (!isLast) const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0E6D8), indent: 56),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _appTile(AppInfo app) {
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
                color: const Color(0xFFF0E6D8),
                child: const Icon(Icons.apps_rounded, color: Color(0xFFB08A5A), size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name ?? app.packageName ?? '',
                style: const TextStyle(color: Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w600), // 👈 was 14, no weight
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24, // 👈 was 22
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7DD3B0) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF7DD3B0) : const Color(0xFFF0E6D8), width: 1.5),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF0F4A32), size: 16) : null, // 👈 was 14
            ),
          ],
        ),
      ),
    );
  }
}