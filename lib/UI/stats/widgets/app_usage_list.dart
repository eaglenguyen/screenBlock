import 'dart:io';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stats_state.dart';

class AppUsageList extends StatelessWidget {
  const AppUsageList({
    super.key,
    required this.stats,
  });

  final List<AppUsageStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      if (Platform.isAndroid) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context), width: 0.5),
          ),
          child: Center(
            child: Text(
              'No usage data for this day',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👇 new header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Most Used',
                style: AppTextStyles.headlineSmall.copyWith( // 👈 was labelMedium+fontSize:20 — now headlineSmall (18)
                  color: AppColors.textPrimary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold(context).withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Screen Time',
                  style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall+fontSize:12 — now bodyMedium (13)
                    color: AppColors.gold(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border(context),
              width: 0.5,
            ),
          ),
          child: Column(
            children: List.generate(stats.length, (index) {
              final stat = stats[index];
              final isLast = index == stats.length - 1;
              return Column(
                children: [
                  _AppUsageRow(stat: stat),
                  if (!isLast)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border(context),
                      indent: 60,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AppUsageRow extends StatefulWidget {
  const _AppUsageRow({required this.stat});
  final AppUsageStat stat;

  @override
  State<_AppUsageRow> createState() => _AppUsageRowState();
}

class _AppUsageRowState extends State<_AppUsageRow>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  AppInfo? _appInfo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.stat.proportion,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
    _loadAppInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await InstalledApps.getAppInfo(
        widget.stat.packageName,
      );
      if (mounted) setState(() => _appInfo = info);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.stat.appName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.stat.formattedTime,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _widthAnimation,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSubtle(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 4,
                        width: constraints.maxWidth *
                            _widthAnimation.value,
                        decoration: BoxDecoration(
                          color: AppColors.gold(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (_appInfo?.icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          _appInfo!.icon!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child:  Icon(
        Icons.apps_rounded,
        color: AppColors.textSecondary(context),
        size: 18,
      ),
    );
  }
}