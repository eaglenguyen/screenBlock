import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../service/app_store_search_result.dart';
import '../service/app_store_search_service.dart';

class AppStoreSearchSheet extends StatefulWidget {
  const AppStoreSearchSheet({super.key});

  @override
  State<AppStoreSearchSheet> createState() => _AppStoreSearchSheetState();
}

class _AppStoreSearchSheetState extends State<AppStoreSearchSheet> {
  final _controller = TextEditingController();
  final _service = AppStoreSearchService();
  List<AppStoreSearchResult> _results = [];
  List<AppStoreSearchResult> _popularApps = [];
  bool _isLoadingPopular = true;
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounce;

  AppStoreSearchResult? _selectedResult;

  @override
  void initState() {
    super.initState();
    _loadPopularApps();
  }

  Future<void> _loadPopularApps() async {
    final apps = await _service.fetchPopularApps();
    if (mounted) {
      setState(() {
        _popularApps = apps;
        _isLoadingPopular = false;
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _isSearching = value.trim().isNotEmpty);
    if (value.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);
      final results = await _service.search(value);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _selectResult(AppStoreSearchResult result) {
    setState(() => _selectedResult = result);
  }

  Future<void> _confirm() async {
    if (_selectedResult != null) {
      Navigator.pop(context, _selectedResult);
    }
  }

  String? get _confirmLabel => _selectedResult?.trackName;

  @override
  Widget build(BuildContext context) {
    final canConfirm = _confirmLabel != null;
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
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary(context)),
                ),
                Expanded(
                  child: Text(
                    'Which app is this?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              'To display your app correctly, please confirm which app you selected to be blocked.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context)),
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search app',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary(context), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(context)
                : _buildPopularApps(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm ? AppColors.accent(context) : AppColors.backgroundSubtle(context),
                  foregroundColor: canConfirm ? AppColors.accentText(context) : AppColors.textSecondary(context),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: Text(canConfirm ? 'This is $_confirmLabel' : 'This is...'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularApps(BuildContext context) {
    if (_isLoadingPopular) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent(context)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        Text(
          'Popular apps',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(_popularApps.length, (i) {
              final app = _popularApps[i];
              final isSelected = _selectedResult?.trackId == app.trackId;
              final isLast = i == _popularApps.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () => _selectResult(app),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      color: isSelected ? AppColors.accent(context).withValues(alpha: 0.1) : null,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: app.artworkUrl != null
                                ? Image.network(app.artworkUrl!, width: 32, height: 32, fit: BoxFit.cover)
                                : Container(width: 32, height: 32, color: AppColors.backgroundCard(context)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(app.trackName, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context))),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: AppColors.accent(context), size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 58),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.accent(context)));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('No apps found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final isSelected = _selectedResult?.trackId == result.trackId;
        return InkWell(
          onTap: () => _selectResult(result),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: isSelected ? AppColors.accent(context).withValues(alpha: 0.1) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: result.artworkUrl != null
                      ? Image.network(result.artworkUrl!, width: 36, height: 36, fit: BoxFit.cover)
                      : Container(
                    width: 36,
                    height: 36,
                    color: AppColors.backgroundSubtle(context),
                    child: Icon(Icons.apps_rounded, color: AppColors.textSecondary(context), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.trackName,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 14, color: AppColors.textPrimary(context)),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: AppColors.accent(context), size: 20)
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}