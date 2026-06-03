import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:screenblock/features/stats/stats_state.dart';
import 'package:screenblock/features/stats/stats_viewmodel.dart';
import 'package:screenblock/features/stats/widgets/app_usage_list.dart';
import 'package:screenblock/features/stats/widgets/usage_gauge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../core/constants/hivebox_names.dart';


class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() =>
      _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsViewModelProvider.notifier).loadStats();
    });
  }

  void _showGoalPicker(BuildContext context) {
    // start at current saved value
    double selectedHours = StatsState.loadGoalHours();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalMinutes = (selectedHours * 60).round();
          final hours = totalMinutes ~/ 60;
          final minutes = totalMinutes % 60;

          String formattedLabel() {
            if (hours == 0) return '${minutes}m';
            if (minutes == 0) return '${hours}h';
            return '${hours}h ${minutes}m';
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E35),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Daily Screen Time Goal',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 32),

                // big time display
                Text(
                  formattedLabel(),
                  style: const TextStyle(
                    color: Color(0xFFEDB82A),
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'per day',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFEDB82A),
                    inactiveTrackColor:
                    const Color(0xFFEDB82A).withValues(alpha: 0.15),
                    thumbColor: const Color(0xFFEDB82A),
                    overlayColor:
                    const Color(0xFFEDB82A).withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    trackHeight: 5,
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    value: selectedHours,
                    min: 0.5,
                    max: 7.0,
                    divisions: 13, // 0.5h increments = 13 steps
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setModalState(() => selectedHours = val);
                    },
                  ),
                ),

                // min/max labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '30m',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '7h',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final box = Hive.box(HiveBoxNames.settings);
                      await box.put(
                        'dailyScreenTimeGoal',
                        selectedHours,
                      );
                      if (context.mounted) Navigator.pop(context);
                      ref
                          .read(statsViewModelProvider.notifier)
                          .loadStats();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDB82A),
                      foregroundColor: const Color(0xFF1A1208),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Save Goal'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {

    final state = ref.watch(statsViewModelProvider);



    return Scaffold(

      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
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

  // ── Header ───────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1e1e40), AppColors.background],
        ),
      ),
      child: Row(
        children: [
          Text(
            "Today's Screen Time",
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (Platform.isIOS) ...[
            _iconButton(
              icon: Icons.access_time_rounded,
              onTap: () async {
                await const MethodChannel(
                  'com.eagle.screenblock/ios_blocking',
                ).invokeMethod('openScreenTime');
              },
            ),
            const SizedBox(width: 8),
          ],
          _iconButton(
            icon: Icons.refresh_rounded,
            onTap: () => ref
                .read(statsViewModelProvider.notifier)
                .loadStats(),
          ),
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.punch_clock,
            onTap: () => _showGoalPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ),
    );
  }

  // ── Content ──────────────────────────────────────
  Widget _buildContent(StatsState state) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: () => ref
          .read(statsViewModelProvider.notifier)
          .loadStats(),
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

  // ── Error ────────────────────────────────────────
  Widget _buildError(String error) {
    final isPermission =
        error.contains('permission') ||
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