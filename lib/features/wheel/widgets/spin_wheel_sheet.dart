// lib/features/wheel/widgets/spin_wheel_sheet.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../wheel_viewmodel.dart';
import 'edit_wheel_item_sheet.dart';
import 'wheel_painter.dart';

class SpinWheelSheet extends ConsumerStatefulWidget {
  const SpinWheelSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const SpinWheelSheet(),
    );
  }

  @override
  ConsumerState<SpinWheelSheet> createState() => _SpinWheelSheetState();
}

class _SpinWheelSheetState extends ConsumerState<SpinWheelSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRotation = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    final items = ref.read(wheelViewModelProvider).items;
    if (items.isEmpty || ref.read(wheelViewModelProvider).isSpinning) return;

    ref.read(wheelViewModelProvider.notifier).clearResult();
    ref.read(wheelViewModelProvider.notifier).setSpinning(true);
    HapticFeedback.mediumImpact();

    final segmentAngle = 2 * pi / items.length;
    final fullSpins = 5 + _random.nextInt(3); // 5–7 full turns
    final randomOffset = _random.nextDouble() * 2 * pi;
    final targetRotation = _currentRotation + fullSpins * 2 * pi + randomOffset;

    _animation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _controller.reset();
    _controller.forward().then((_) {
      _currentRotation = targetRotation % (2 * pi);

      // determine which segment landed under the top pointer
      final normalized = (2 * pi - (targetRotation % (2 * pi))) % (2 * pi);
      final index = (normalized / segmentAngle).floor().clamp(0, items.length - 1);

      HapticFeedback.heavyImpact();
      ref.read(wheelViewModelProvider.notifier).setResult(items[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wheelViewModelProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Spin the Wheel',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => EditWheelItemsSheet.show(context),
                child: Icon(Icons.edit_rounded, color: AppColors.textSecondary(context), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.items.isEmpty)
            _buildEmptyState(context)
          else ...[
            _buildWheel(context, state),
            const SizedBox(height: 24),
            if (state.lastResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent(context).withValues(alpha: 0.3), width: 0.5),
                ),
                child: Column(
                  children: [
                    Text('Your pick:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 4),
                    Text(
                      state.lastResult!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.accent(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: state.isSpinning ? null : _spin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent(context),
                foregroundColor: AppColors.accentText(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.labelLarge,
              ),
              child: Text(state.isSpinning ? 'Spinning...' : 'Spin'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Text(
          'No items yet — add a few things\nto spin for instead of scrolling!',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => EditWheelItemsSheet.show(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent(context),
            foregroundColor: AppColors.accentText(context),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: const StadiumBorder(),
          ),
          child: const Text('Add Items'),
        ),
      ],
    );
  }

  Widget _buildWheel(BuildContext context, state) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final rotation = _controller.isAnimating ? _animation.value : _currentRotation;
              return CustomPaint(
                size: const Size(260, 260),
                painter: WheelPainter(items: state.items, rotation: rotation),
              );
            },
          ),
          // center hub
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context), width: 2),
            ),
          ),
          // pointer, fixed at top
          Positioned(
            top: -6,
            child: Icon(Icons.arrow_drop_down_rounded, size: 40, color: AppColors.accent(context)),
          ),
        ],
      ),
    );
  }
}