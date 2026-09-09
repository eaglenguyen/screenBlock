// lib/UI/wheel/wheel_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/UI/wheel/wheel_viewmodel.dart';
import 'package:pausenow/UI/wheel/widgets/paste_list_tutorial_overlay.dart';
import 'package:pausenow/UI/wheel/widgets/wheel_painter.dart';
import '../../core/constants/hivebox_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'data/wheel_presets.dart';


class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRotation = 0;
  final Random _random = Random();
  final _textController = TextEditingController();
  bool _isPasteMode = false; // 👈 new

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
    _textController.dispose();
    super.dispose();
  }

  void _spin() {
    final items = ref.read(wheelViewModelProvider).items;
    if (items.isEmpty || ref.read(wheelViewModelProvider).isSpinning) return;

    ref.read(wheelViewModelProvider.notifier).clearResult();
    ref.read(wheelViewModelProvider.notifier).setSpinning(true);
    HapticFeedback.mediumImpact();

    final segmentAngle = 2 * pi / items.length;
    final fullSpins = 5 + _random.nextInt(3);
    final randomOffset = _random.nextDouble() * 2 * pi;
    final targetRotation = _currentRotation + fullSpins * 2 * pi + randomOffset;

    _animation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _controller.reset();
    _controller.forward().then((_) {
      _currentRotation = targetRotation % (2 * pi);
      final normalized = (2 * pi - (targetRotation % (2 * pi))) % (2 * pi);
      final index = (normalized / segmentAngle).floor().clamp(0, items.length - 1);
      HapticFeedback.heavyImpact();
      ref.read(wheelViewModelProvider.notifier).setResult(items[index]);
    });
  }

  void _submitNewItem() {
    if (_isPasteMode) {
      // 👇 split on paragraph breaks (blank lines) or single newlines, whichever the user typed
      final raw = _textController.text;
      final entries = raw
          .split(RegExp(r'\n+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      for (final entry in entries) {
        ref.read(wheelViewModelProvider.notifier).addItem(entry);
      }
    } else {
      ref.read(wheelViewModelProvider.notifier).addItem(_textController.text);
    }
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wheelViewModelProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = (screenWidth - 48).clamp(0, 320).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Spin the Wheel',
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary(context)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: state.items.isEmpty
                      ? _buildEmptyState(context)
                      : Column(
                    children: [
                      _buildWheel(context, state, wheelSize), // 👈 now tappable
                      const SizedBox(height: 16),
                      Text(
                        state.isSpinning ? 'Spinning...' : 'Tap the wheel to spin', // 👈 new — replaces the button
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                      ),
                      if (state.lastResult != null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
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
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entries (${state.items.length})',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (!_isPasteMode) {
                          // final box = Hive.box(HiveBoxNames.settings); // 👈 commented out for testing
                          // final seenTutorial = box.get('seenPasteListTutorial', defaultValue: false) as bool;
                          // if (!seenTutorial) {
                          await PasteListTutorialOverlay.show(context);
                          // await box.put('seenPasteListTutorial', true);
                          // }
                        }
                        setState(() => _isPasteMode = !_isPasteMode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isPasteMode ? AppColors.accent(context).withValues(alpha: 0.15) : AppColors.backgroundSubtle(context),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _isPasteMode ? AppColors.accent(context).withValues(alpha: 0.4) : AppColors.border(context),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.content_paste_rounded,
                              size: 14,
                              color: _isPasteMode ? AppColors.accent(context) : AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Paste list',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _isPasteMode ? AppColors.accent(context) : AppColors.textSecondary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _isPasteMode
                    ? Column( // 👈 new — multi-line paste box
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      minLines: 3,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        hintText: 'Paste or type a list — one item per line...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                        filled: true,
                        fillColor: AppColors.backgroundSubtle(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitNewItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent(context),
                          foregroundColor: AppColors.accentText(context),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Add all'),
                      ),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: 'Add an item...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                          filled: true,
                          fillColor: AppColors.backgroundSubtle(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _submitNewItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submitNewItem,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, color: AppColors.accentText(context), size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = state.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref.read(wheelViewModelProvider.notifier).removeItem(item),
                              child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: state.items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'No items yet — add a few\nthings to spin for!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(wheelViewModelProvider.notifier).addPresetList(WheelPresets.defaultList),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.accentText(context),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: const StadiumBorder(),
            ),
            child: const Text('Use suggested list'),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(BuildContext context, state, double size) {
    return GestureDetector( // 👈 new — wheel itself is tappable
      onTap: state.isSpinning ? null : _spin,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final rotation = _controller.isAnimating ? _animation.value : _currentRotation;
                return CustomPaint(
                  size: Size(size, size),
                  painter: WheelPainter(items: state.items, rotation: rotation),
                );
              },
            ),
            Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context), width: 2),
              ),
            ),
            Positioned(
              top: -8,
              child: Icon(Icons.arrow_drop_down_rounded, size: 44, color: AppColors.accent(context)),
            ),
          ],
        ),
      ),
    );
  }
}