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
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            'No usage data for today yet',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
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
                const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.border,
                  indent: 60,
                ),
            ],
          );
        }),
      ),
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
        horizontal: 14,
        vertical: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 10),
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
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                          color: AppColors.backgroundSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 4,
                        width: constraints.maxWidth *
                            _widthAnimation.value,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
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
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.apps_rounded,
        color: AppColors.textSecondary,
        size: 18,
      ),
    );
  }
}