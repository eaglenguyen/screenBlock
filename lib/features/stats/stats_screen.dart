import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenblock/features/stats/stats_state.dart';
import 'package:screenblock/features/stats/stats_viewmodel.dart';
import 'package:screenblock/features/stats/widgets/app_usage_list.dart';
import 'package:screenblock/features/stats/widgets/stats_header.dart';
import 'package:screenblock/features/stats/widgets/usage_gauge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsViewModelProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StatsHeader(),
          Expanded(
            child: state.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            )
                : state.error != null
                ? _buildError(state.error!)
                : _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StatsState state) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () =>
          ref.read(statsViewModelProvider.notifier).loadStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        child: Column(
          children: [
            UsageGauge(state: state),
            const SizedBox(height: 12),
            AppUsageList(stats: state.appStats),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    final isPermission = error.contains('permission') ||
        error.contains('SecurityException');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isPermission
                  ? 'Usage access required'
                  : 'Could not load stats',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermission
                  ? 'Grant usage access in settings to see your screen time'
                  : error,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (isPermission) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.goldText,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Text('Grant Permission'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}