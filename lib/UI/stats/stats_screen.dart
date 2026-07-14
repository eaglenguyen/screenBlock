import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pausenow/UI/stats/stats_state.dart';
import 'package:pausenow/UI/stats/stats_viewmodel.dart';
import 'package:pausenow/UI/stats/widgets/app_usage_list.dart';
import 'package:pausenow/UI/stats/widgets/stats_header.dart';
import 'package:pausenow/UI/stats/widgets/usage_gauge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dart:io';


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
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          const StatsHeader(),
          Expanded(
            child: state.isLoading
                ?  Center(
              child: CircularProgressIndicator(
                color: AppColors.gold(context),
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

  Widget _buildScreenTimeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  color: AppColors.gold(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,

                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 👇 replaced the button+sheet with an inline embedded report
          SizedBox(
            height: 500, // 👈 adjust to taste
            child: UiKitView(
              viewType: 'com.eagle.pausenow/screen_time_report_view',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StatsState state) {
    return RefreshIndicator(
      color: AppColors.gold(context),
      backgroundColor: AppColors.backgroundCard(context),
      onRefresh: () => ref.read(statsViewModelProvider.notifier).loadStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        child: Column(
          children: [
            UsageGauge(state: state),
            const SizedBox(height: 12),
            if (Platform.isIOS)
              _buildScreenTimeCard(context),
            if (!Platform.isIOS)
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
             Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary(context),
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
                onPressed: () => ref
                    .read(statsViewModelProvider.notifier)
                    .requestUsagePermission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold(context),
                  foregroundColor: AppColors.goldText(context),
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