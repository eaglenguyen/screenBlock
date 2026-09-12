import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/features/quickblock/widgets/quick_block_tutorial.dart';
import '../../../core/constants/hivebox_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pressable_scale.dart';
import '../../../core/utils/permission_dialogs.dart';
import '../../../domain/platform/ios_blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import '../quick_block_viewmodel.dart';
import 'dialog_unblock.dart';

class QuickBlockApp {
  final String name;
  final String iconAsset;
  final Color iconColor;
  final Color bgColor;
  final String packageName;

  const QuickBlockApp({
    required this.name,
    required this.iconAsset,
    required this.iconColor,
    required this.bgColor,
    required this.packageName,
  });
}

const quickBlockApps = [
  QuickBlockApp(name: 'TikTok', iconAsset: 'assets/icons/tiktok.svg', iconColor: Colors.white, bgColor: Color(0xFFDCEBFF), packageName: 'com.zhiliaoapp.musically'),
  QuickBlockApp(name: 'Instagram', iconAsset: 'assets/icons/instagram.svg', iconColor: Color(0xFFC2478B), bgColor: Color(0xFFFFE1EC), packageName: 'com.instagram.android'),
  QuickBlockApp(name: 'YouTube', iconAsset: 'assets/icons/youtube.svg', iconColor: Color(0xFFB07A1E), bgColor: Color(0xFFFFE8B8), packageName: 'com.google.android.youtube'),
  QuickBlockApp(name: 'Snapchat', iconAsset: 'assets/icons/snapchat.svg', iconColor: Color(0xFFB89400), bgColor: Color(0xFFFFF4B8), packageName: 'com.snapchat.android'),
  QuickBlockApp(name: 'Twitter', iconAsset: 'assets/icons/twitter-x.svg', iconColor: Colors.black, bgColor: Color(0xFFE8E8E8), packageName: 'com.twitter.android'),
  QuickBlockApp(name: 'Facebook', iconAsset: 'assets/icons/facebook.svg', iconColor: Color(0xFF1877F2), bgColor: Color(0xFFDCEBFF), packageName: 'com.facebook.katana'),
];

class QuickBlockRow extends ConsumerStatefulWidget {
  final bool reverseOnBuild;
  const QuickBlockRow({super.key, this.reverseOnBuild = false});

  @override
  ConsumerState<QuickBlockRow> createState() => _QuickBlockRowState();
}

class _QuickBlockRowState extends ConsumerState<QuickBlockRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnims;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 900),
    );
    _itemAnims = List.generate(quickBlockApps.length, (i) {
      final start = (i * 0.1).clamp(0.0, 0.7);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(QuickBlockRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reverseOnBuild && !oldWidget.reverseOnBuild) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedBlock(int index, Widget child) {
    final anim = _itemAnims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: anim.value.clamp(0.0, 1.0),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, List<QuickBlockApp> apps, int indexOffset) {
    final blocked = ref.watch(quickBlockViewModelProvider);
    final notifier = ref.read(quickBlockViewModelProvider.notifier);

    return Row(
      children: apps.asMap().entries.map((entry) {
        final localIndex = entry.key;
        final app = entry.value;
        final globalIndex = indexOffset + localIndex;
        final isBlocked = blocked.contains(app.packageName);
        return Expanded(
          child: _animatedBlock(
            globalIndex,
            PressableScale(
              onTap: () => checkAccessibilityAndProceed(
                context,
                ref,
                    () async {
                  if (isBlocked) { // 👈 new — about to unblock, show the choice dialog first
                    final shouldUnblock = await QuickBlockUnblockDialog.show(context, appName: app.name);
                    if (!shouldUnblock) return; // user chose to spin instead, or dialog was dismissed
                    notifier.toggle(app.packageName);
                    return;
                  }

                  // 👇 existing block-flow logic unchanged, only runs when currently unblocked (about to block)
                  if (Platform.isIOS) {
                    final service = ref.read(blockingServiceProvider) as IOSBlockingService;
                    final hasSelection = await service.hasQuickBlockSelection(app.packageName);
                    if (!hasSelection) {
                      final box = Hive.box(HiveBoxNames.settings);
                      final seenTutorial = box.get('seenQuickBlockTutorial', defaultValue: false) as bool;
                      if (!seenTutorial) {
                        await QuickBlockPickerTutorialOverlay.show(context, appName: app.name);
                      }
                      final count = await service.showQuickBlockPicker(cardId: app.packageName, appLabel: app.name);
                      if (count == null || count == 0) return;
                    }
                  }
                  notifier.toggle(app.packageName);
                },
              ),
              child: SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 4,
                              left: 6,
                              right: 6,
                              bottom: -8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardLip(context),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 112,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.backgroundSubtle(context)
                                    : app.bgColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(app.iconAsset, width: 24, height: 24,
                                      colorFilter: ColorFilter.mode(app.iconColor, BlendMode.srcIn)),
                                  const SizedBox(height: 6),
                                  Text(app.name, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w600)), // 👈 was bodySmall fontSize:11
                                  const SizedBox(height: 4),
                                  Text(
                                    isBlocked ? 'Blocked' : 'Tap to block',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 10, // 👈 was 9
                                      color: isBlocked ? AppColors.error(context) : AppColors.textSecondary(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isBlocked)
                        Positioned.fill(
                          child: Align(
                            alignment: const Alignment(0, -0.7),
                            child: Icon(Icons.close_rounded, color: AppColors.error(context), size: 60),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, ref, quickBlockApps.sublist(0, 3), 0),
        const SizedBox(height: 8),
        _buildRow(context, ref, quickBlockApps.sublist(3, 6), 3),
      ],
    );
  }
}