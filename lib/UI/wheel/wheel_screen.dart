import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pausenow/UI/wheel/wheel_viewmodel.dart';
import 'package:pausenow/UI/wheel/widgets/paste_list_tutorial_overlay.dart';
import 'package:pausenow/UI/wheel/widgets/wheel_painter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../paywall/feature_paywall_screen.dart';
import '../../providers/premium_provider.dart';
import '../settings/widgets/hard_mode_gate.dart';
import 'data/wheel_presets.dart';

class _WheelTitle extends StatefulWidget {
  @override
  State<_WheelTitle> createState() => _WheelTitleState();
}

class _WheelTitleState extends State<_WheelTitle> with SingleTickerProviderStateMixin {
  late AnimationController _wiggleController;
  late Animation<double> _wiggle;




  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _wiggle = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'instead of '),
              TextSpan(
                text: 'doomscrolling',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                ),
              ),
              const TextSpan(text: ','),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _wiggle,
              builder: (context, child) => Transform.rotate(
                angle: _wiggle.value,
                alignment: Alignment.bottomLeft,
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spin the wheel!',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
  bool _isPasteMode = false;
  bool _entriesExpanded = true;

  late ConfettiController _confettiController;
  AudioPlayer? _spinPlayer;
  AudioPlayer? _landPlayer;
  Color _confettiColor = const Color(0xFFF7C948);

  Timer? _cooldownTicker; // 👈 new — drives the live countdown display

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Name your list',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: 'e.g. Things to do instead',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
            filled: true,
            fillColor: AppColors.backgroundSubtle(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterText: '',
          ),
          onSubmitted: (value) {
            ref.read(wheelViewModelProvider.notifier).setListName(value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(wheelViewModelProvider.notifier).setListName(controller.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.accentText(context),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommitModeButton(BuildContext context, state) {
    final isEnabled = state.commitModeEnabled;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: GestureDetector(
        onTap: () => _handleCommitModeTap(context, state),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              gradient: const LinearGradient( // 👈 always applied now
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8623D),
                  Color(0xFFF2A340),
                ],
              ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isEnabled ? const Color(0xFFE8623D) : AppColors.border(context),
              width: isEnabled ? 1.5 : 0.5,
            ),
            boxShadow: isEnabled // 👈 new — subtle glow matching the gradient color
                ? [BoxShadow(color: const Color(0xFFF2A340).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEnabled ? Colors.black : Colors.transparent, // 👈 white dot reads better on the orange gradient than another orange
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STRICT\nMODE', // 👈 updated label to match your rename
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white, // 👈 white text on the gradient for contrast
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCommitModeTap(BuildContext context, state) async {
    if (!state.commitModeEnabled) {
      _showCommitModeEnableConfirmation(context, () { // 👈 no premium check before this anymore
        final isPremium = ref.read(isPremiumProvider); // 👈 new — checked when Enable is actually pressed
        if (!isPremium) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (_) => const FeaturePaywallScreen(source: 'strict_mode'),
          );
          return;
        }
        ref.read(wheelViewModelProvider.notifier).toggleCommitMode();
      });
    } else {
      final solved = await HardModeMathGate.show(context);
      if (solved) {
        ref.read(wheelViewModelProvider.notifier).toggleCommitMode();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // 👇 fixed — deferred until after the current build finishes, since modifying
    // a provider synchronously inside initState throws
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = ref.read(wheelViewModelProvider);
      if (currentState.isSpinning) {
        ref.read(wheelViewModelProvider.notifier).setSpinning(false);
      }
    });

    _spinPlayer = AudioPlayer();
    _spinPlayer!.setAsset('assets/sounds/spinSound.m4a').then((_) {
      _spinPlayer!.setLoopMode(LoopMode.off);
      _spinPlayer!.setVolume(0.6);
    });

    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final wasInCooldown = ref.read(wheelViewModelProvider).isInCooldown;
      ref.read(wheelViewModelProvider.notifier).checkCooldownExpiry();
      if (wasInCooldown) setState(() {});
    });
  }

  @override
  void dispose() {
    // 👇 dispose() runs outside the build phase, so this one is actually safe as-is —
    // no change needed here, but wrapped in try/catch defensively regardless
    try {
      if (ref.read(wheelViewModelProvider).isSpinning) {
        ref.read(wheelViewModelProvider.notifier).setSpinning(false);
      }
    } catch (_) {}
    _controller.dispose();
    _textController.dispose();
    _confettiController.dispose();
    _spinPlayer?.dispose();
    _landPlayer?.dispose();
    _cooldownTicker?.cancel();
    super.dispose();
  }

  late VoidCallback _tickListener;
  double _lastTickAngle = 0;

  void _spin() {
    final wheelState = ref.read(wheelViewModelProvider);
    final items = wheelState.items;
    if (items.isEmpty || wheelState.isSpinning) return;
    if (!wheelState.canSpin) {
      HapticFeedback.heavyImpact();
      return;
    }

    ref.read(wheelViewModelProvider.notifier).clearResult();
    ref.read(wheelViewModelProvider.notifier).setSpinning(true);
    HapticFeedback.mediumImpact();

    try {
      _spinPlayer?.seek(Duration.zero);
      _spinPlayer?.play();
    } catch (_) {}

    final segmentAngle = 2 * pi / items.length;
    final fullSpins = 5 + _random.nextInt(3);
    final randomOffset = _random.nextDouble() * 2 * pi;
    final targetRotation = _currentRotation + fullSpins * 2 * pi + randomOffset;

    _animation = Tween<double>(begin: _currentRotation, end: targetRotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    // 👇 new — fires a light tick every time the wheel crosses a segment boundary
    _lastTickAngle = _currentRotation;
    _tickListener = () {
      final current = _animation.value;
      final crossedSegments = ((current - _lastTickAngle).abs() / segmentAngle).floor();
      if (crossedSegments >= 1) {
        HapticFeedback.selectionClick(); // lightest haptic available — right for a rapid repeated tick
        _lastTickAngle = current;
      }
    };
    _controller.addListener(_tickListener);

    _controller.reset();
    _controller.forward().then((_) {
      _controller.removeListener(_tickListener); // 👈 new — clean up
      _currentRotation = targetRotation % (2 * pi);
      final normalized = (2 * pi - (targetRotation % (2 * pi))) % (2 * pi);
      final index = (normalized / segmentAngle).floor().clamp(0, items.length - 1);
      HapticFeedback.heavyImpact();

      setState(() {
        final isDark = Theme.of(context).brightness == Brightness.dark; // 👈 new
        final palette = WheelPainter.colorsFor(isDark); // 👈 new
        _confettiColor = palette[index % palette.length]; // 👈 was WheelPainter.colors[index % WheelPainter.colors.length]
      });

      try {
        _landPlayer?.seek(Duration.zero);
        _landPlayer?.play();
      } catch (_) {}

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });

      ref.read(wheelViewModelProvider.notifier).setResult(items[index]);
      ref.read(wheelViewModelProvider.notifier).recordSpin();
    });
  }

  void _submitNewItem() {
    if (_isPasteMode) {
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

  String _formatCooldown(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wheelViewModelProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = (screenWidth - 48).clamp(0, 320).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = WheelPainter.colorsFor(isDark);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row( // 👈 new — wraps title + button together
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _WheelTitle()),
                        _buildCommitModeButton(context, ref.watch(wheelViewModelProvider)), // 👈 new
                      ],
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
                          _buildWheel(context, state, wheelSize),
                          const SizedBox(height: 12),
                          if (state.commitModeEnabled) // 👈 new — status line under the wheel
                            _buildCommitModeStatus(context, state),
                          if (state.lastResult != null) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _confettiColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _confettiColor.withValues(alpha: 0.3), width: 0.5),
                                ),
                                child: Column(
                                  children: [
                                    Text('Your pick:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.lastResult!,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: _confettiColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
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
                        GestureDetector(
                          onTap: () => setState(() => _entriesExpanded = !_entriesExpanded),
                          child: Row(
                            children: [
                              AnimatedRotation(
                                turns: _entriesExpanded ? 0 : -0.25,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.listName} (${state.items.length})', // 👈 was 'Entries (${state.items.length})'
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6), // 👈 new
                              GestureDetector( // 👈 new — separate tap target for renaming, doesn't trigger collapse
                                onTap: () => _showRenameDialog(context, state.listName),
                                child: Icon(Icons.edit_rounded, size: 14, color: AppColors.textSecondary(context)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (_isPasteMode) ...[
                              GestureDetector(
                                onTap: _submitNewItem,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundSubtle(context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_rounded, color: AppColors.textSecondary(context), size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            GestureDetector(
                              onTap: () async {
                                if (!_isPasteMode) {
                                  await PasteListTutorialOverlay.show(context);
                                }
                                setState(() => _isPasteMode = !_isPasteMode);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isPasteMode ? AppColors.textPrimary(context).withValues(alpha: 0.15) : AppColors.backgroundSubtle(context),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: _isPasteMode ? AppColors.textPrimary(context).withValues(alpha: 0.4) : AppColors.border(context),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.content_paste_rounded,
                                      size: 14,
                                      color: _isPasteMode ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Paste list',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: _isPasteMode ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _entriesExpanded
                        ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: _isPasteMode
                          ? Column(
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
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSubtle(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_rounded, color: AppColors.textSecondary(context), size: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox(width: double.infinity),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _entriesExpanded
                        ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                      child: state.items.isEmpty
                          ? const SizedBox.shrink()
                          : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 6,
                            left: 4,
                            right: 4,
                            bottom: -8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardLip(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard(context),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(state.items.length, (index) {
                                final item = state.items[index];
                                final isLast = index == state.items.length - 1;
                                final color = palette[index % palette.length];
                                return Column(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.18),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: AppTextStyles.bodyLarge.copyWith(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary(context),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => ref.read(wheelViewModelProvider.notifier).removeItem(item),
                                                child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 20),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 60, endIndent: 16),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox(width: double.infinity, height: 120),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                key: ValueKey(_confettiColor.toARGB32()),
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.3,
                colors: [
                  _confettiColor,
                  _confettiColor.withValues(alpha: 0.8),
                  Colors.white,
                  HSLColor.fromColor(_confettiColor).withLightness(
                    (HSLColor.fromColor(_confettiColor).lightness + 0.2).clamp(0.0, 1.0),
                  ).toColor(),
                ],
              ),
            ),
            IgnorePointer( // 👈 new — the spotlight overlay, doesn't block taps
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: state.isSpinning ? 1.0 : 0.0,
                child: _SpinSpotlight(wheelKey: _wheelKey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 new — shows remaining spins, or the cooldown countdown once locked out
  Widget _buildCommitModeStatus(BuildContext context, state) {
    if (state.isInCooldown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.error(context)),
            const SizedBox(width: 6),
            Text(
              'Locked — ${_formatCooldown(state.cooldownRemaining)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _confettiColor.withValues(alpha: 0.12), // 👈 was Color(0xFFF2A340) — now dynamic
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        '${state.spinsRemaining} spin${state.spinsRemaining == 1 ? '' : 's'} left',
        style: AppTextStyles.bodyMedium.copyWith(
          color: _confettiColor, // 👈 was Color(0xFFF2A340) — now dynamic
          fontWeight: FontWeight.w700,
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
          Center(
            child: _BubbleButton(
              label: 'Add suggested list',
              color: AppColors.accentDark(context),
              onTap: () => ref.read(wheelViewModelProvider.notifier).addPresetList(WheelPresets.defaultList),
            ),
          ),
        ],
      ),
    );
  }
  final GlobalKey _wheelKey = GlobalKey(); // 👈 new — add as a field in _WheelScreenState

  Widget _buildWheel(BuildContext context, state, double size) {
    final locked = state.commitModeEnabled && !state.canSpin; // 👈 new
    return GestureDetector(
      onTap: (state.isSpinning || locked) ? null : _spin, // 👈 blocks tap while locked
      child: Opacity( // 👈 new — visually dims the wheel while locked
        opacity: locked ? 0.5 : 1.0,
        child: SizedBox(
          key: _wheelKey, // 👈 new — lets the overlay find the wheel's exact screen position
          width: size,
          height: size + 24,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 24,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final rotation = _controller.isAnimating ? _animation.value : _currentRotation;
                      return CustomPaint(
                        size: Size(size, size),
                        painter: WheelPainter(
                          items: state.items,
                          rotation: rotation,
                          isDark: Theme.of(context).brightness == Brightness.dark, // 👈 new — required param
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                child: CustomPaint(
                  size: const Size(28, 24),
                  painter: _PointerPainter(color: AppColors.textPrimary(context)),
                ),
              ),
              Positioned(
                top: 24 + size / 2 - size * 0.11,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textPrimary(context), width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: locked
                        ? Icon(Icons.lock_rounded, color: AppColors.textPrimary(context), size: 20) // 👈 new — shows a lock instead of "SPIN" text
                        : Text(
                      'SPIN',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}

class _BubbleButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _BubbleButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_BubbleButton> createState() => _BubbleButtonState();
}

class _BubbleButtonState extends State<_BubbleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = Tween<double>(begin: 1.0, end: 0.9)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut))),
      onTapUp: (_) {
        setState(() => _scale = Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)));
        _controller.forward(from: 0);
        widget.onTap();
      },
      onTapCancel: () => _controller.value = 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


void _showCommitModeEnableConfirmation(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.backgroundCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row( // 👈 new — wraps title + PRO badge together
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Strict Mode',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 8),
                Container( // 👈 new — PRO flair
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2A340), // 👈 was AppColors.accent(context) — hardcoded orange
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'PRO',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white, // 👈 was AppColors.accentText(context)
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'After 3 spins, you must wait 5 mins to spin again. Commit to your pick!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 18,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Enable',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


class _SpinSpotlight extends StatefulWidget {
  final GlobalKey wheelKey;
  const _SpinSpotlight({required this.wheelKey});

  @override
  State<_SpinSpotlight> createState() => _SpinSpotlightState();
}

class _SpinSpotlightState extends State<_SpinSpotlight> {
  Rect? _rect;

  @override
  void didUpdateWidget(covariant _SpinSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 👇 fixed — defer instead of measuring synchronously mid-rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return; // 👈 new guard
    final ctx = widget.wheelKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return; // 👈 already guards detached, but the element itself can still be inactive
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect != _rect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _rect = rect);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    if (_rect == null) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _SpotlightDimPainter(rect: _rect!),
    );
  }
}

class _SpotlightDimPainter extends CustomPainter {
  final Rect rect;
  const _SpotlightDimPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final center = rect.center;
    final radius = rect.longestSide * 0.85;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.75),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightDimPainter old) => old.rect != rect;
}



