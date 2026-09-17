// lib/onboarding_new/screens/demo_video_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart';

class OnboardingDemoVideoScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingDemoVideoScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingDemoVideoScreen> createState() => _OnboardingDemoVideoScreenState();
}

class _IconSpec {
  final bool fromLeft;
  final String? asset;
  final IconData? iconData;
  final Color? iconColor;
  final Color? bg;
  final double targetX;
  final double targetY;
  final double delay;

  const _IconSpec({
    required this.fromLeft,
    this.asset,
    this.iconData,
    this.iconColor,
    this.bg,
    required this.targetX,
    required this.targetY,
    required this.delay,
  });
}

class _DemoPhase {
  final Duration pauseAt;
  final double dx;
  final double dy;
  final String label;
  final bool labelAbove;
  final String? pointerEmoji;

  const _DemoPhase({
    required this.pauseAt,
    required this.dx,
    required this.dy,
    required this.label,
    this.labelAbove = false,
    this.pointerEmoji,
  });
}

class _OnboardingDemoVideoScreenState extends State<OnboardingDemoVideoScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _showCloseButton = false;
  bool _videoEnded = false;

  late AnimationController _iconController;
  late AnimationController _expandController;
  bool _isExpanding = false;
  Rect? _phoneStartRect;

  final GlobalKey _phoneKey = GlobalKey();

  final _icons = const [
    _IconSpec(fromLeft: true, asset: 'assets/icons/instagram.png', targetX: -140, targetY: -100, delay: 0.0),
    _IconSpec(fromLeft: true, asset: 'assets/icons/youtube.png', targetX: -148, targetY: 70, delay: 0.15),
    _IconSpec(fromLeft: false, asset: 'assets/icons/twitter.png', targetX: 140, targetY: -120, delay: 0.05),
    _IconSpec(fromLeft: false, asset: 'assets/icons/tiktok.png', targetX: 148, targetY: 20, delay: 0.2),
  ];

  final _phases = const [
    _DemoPhase(pauseAt: Duration(seconds: 1, milliseconds: 100), dx: 0.81, dy: 0.60, label: 'Tap to block'),
    _DemoPhase(pauseAt: Duration(seconds: 4, milliseconds: 300), dx: 0.5, dy: 0.87, label: 'Tap Spin', labelAbove: true, pointerEmoji: '👇'),
    _DemoPhase(pauseAt: Duration(seconds: 7), dx: 0.5, dy: 0.15, label: 'Tap the notification', pointerEmoji: '👆'),
    _DemoPhase(pauseAt: Duration(seconds: 9, milliseconds: 200), dx: 0.5, dy: 0.415, label: 'Spin the wheel!'),
  ];

  int _currentPhaseIndex = 0;
  bool _showingPhaseOverlay = false;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _iconController.forward();
    });

    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

    _videoController = VideoPlayerController.asset('assets/video/demowheel.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoInitialized = true);
        _videoController.setLooping(false);
        _videoController.addListener(_checkPhaseProgress);
        _videoController.addListener(_checkVideoEnded);
      }).catchError((e) {
        debugPrint('❌ video init error: $e');
      });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _expandController.dispose();
    _videoController.removeListener(_checkPhaseProgress);
    _videoController.removeListener(_checkVideoEnded);
    _videoController.dispose();
    super.dispose();
  }

  void _checkPhaseProgress() {
    if (_showingPhaseOverlay) return;
    if (_currentPhaseIndex >= _phases.length) return;
    if (!_videoController.value.isPlaying) return;

    final target = _phases[_currentPhaseIndex].pauseAt;
    if (_videoController.value.position >= target) {
      _videoController.pause();
      setState(() => _showingPhaseOverlay = true);
      HapticFeedback.mediumImpact();
    }
  }

  void _checkVideoEnded() {
    if (_videoEnded) return;
    final value = _videoController.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _videoEnded = true;
      setState(() => _showCloseButton = true);
      widget.onContinue();
    }
  }

  void _onPhaseTapped() {
    setState(() {
      _showingPhaseOverlay = false;
      _currentPhaseIndex++;
    });
    _videoController.play();
    HapticFeedback.lightImpact();
  }

  void _showMeHow() async {
    final box = _phoneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final topLeft = box.localToGlobal(Offset.zero);
    _phoneStartRect = topLeft & box.size;

    setState(() {
      _isExpanding = true;
      _currentPhaseIndex = 0;
      _videoEnded = false;
    });
    HapticFeedback.mediumImpact();

    await _iconController.reverse();
    await _expandController.forward();

    if (!mounted) return;
    _videoController.seekTo(Duration.zero);
    _videoController.play();
  }

  void _closeFullscreen() async {
    setState(() => _showCloseButton = false);
    HapticFeedback.lightImpact();

    _videoController.pause();
    await _expandController.reverse();
    if (!mounted) return;

    setState(() {
      _isExpanding = false;
      _showingPhaseOverlay = false;
    });
    _iconController.forward();
  }

  // 👇 the ONE shared visual — used both at rest and while growing to fullscreen
  Widget _buildPhoneVisual({required double borderWidth, required double shadowOpacity, required double radius}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF4A3728), width: borderWidth),
        boxShadow: shadowOpacity > 0
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12 * shadowOpacity), blurRadius: 20, offset: const Offset(0, 10))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((radius - borderWidth).clamp(0.0, radius)),
        child: Container(
          color: Colors.black,
          child: _videoInitialized
              ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 1000, // 👈 was _videoController.value.size.width * 1.08 — arbitrary large base, only the ratio matters
              height: 1000 / _videoController.value.aspectRatio, // 👈 was .size.height * 1.15 — now driven by the rotation-correct aspect ratio
              child: VideoPlayer(_videoController),
            ),
          )
              : const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3B0))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const phoneWidth = 250.0;
    final videoAspect = _videoInitialized ? _videoController.value.aspectRatio : (9 / 19.5);
    final phoneHeight = phoneWidth / videoAspect;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isExpanding ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isExpanding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onBack,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const TypewriterTitle(text: 'Awesome 🎉', fontSize: 26, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Spinbrek allows you to spin a wheel before you try to unblock, check it out!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 380,
                        height: 520,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // 👇 resting slot — only visibly renders the phone when NOT expanding.
                            // Once expanding starts, this becomes an invisible placeholder (SizedBox),
                            // so there's zero overlap with the growing overlay below.
                            SizedBox(
                              key: _phoneKey,
                              width: phoneWidth,
                              height: phoneHeight,
                              child: _isExpanding ? null : _buildPhoneVisual(borderWidth: 3, shadowOpacity: 1, radius: 32),
                            ),
                            AnimatedBuilder(
                              animation: _iconController,
                              builder: (context, _) {
                                return Opacity(
                                  opacity: _iconController.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [for (final spec in _icons) _buildIcon(spec)],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isExpanding ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isExpanding,
                      child: OnboardingContinueButton(
                        label: 'Show Me How',
                        onTap: _showMeHow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanding && _phoneStartRect != null)
            AnimatedBuilder(
              animation: _expandController,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_expandController.value);
                final start = _phoneStartRect!;
                final end = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
                final rect = Rect.lerp(start, end, t)!;
                final radius = lerpDouble(32, 0, t)!;
                final borderWidth = lerpDouble(3, 0, t)!;
                final shadowOpacity = (1 - t).clamp(0.0, 1.0);

                return Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: Stack(
                    children: [
                      _buildPhoneVisual(borderWidth: borderWidth, shadowOpacity: shadowOpacity, radius: radius),
                      if (_showingPhaseOverlay && t > 0.98 && _currentPhaseIndex < _phases.length)
                        _PhaseHighlight(
                          phase: _phases[_currentPhaseIndex],
                          frameSize: rect.size,
                          onTap: _onPhaseTapped,
                        ),
                    ],
                  ),
                );
              },
            ),
          if (_showCloseButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showCloseButton ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: _closeFullscreen,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(_IconSpec spec) {
    final start = spec.delay;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final progress = Curves.easeOutBack.transform(
      ((_iconController.value - start) / (end - start)).clamp(0.0, 1.0),
    );

    final startX = spec.fromLeft ? -260.0 : 260.0;
    final currentX = startX + (spec.targetX - startX) * progress;

    final startAngle = spec.fromLeft ? -0.5 : 0.5;
    final restAngle = spec.fromLeft ? -0.12 : 0.12;
    final currentAngle = startAngle + (restAngle - startAngle) * progress;

    return Transform.translate(
      offset: Offset(currentX, spec.targetY),
      child: Transform.rotate(
        angle: currentAngle,
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: spec.asset != null
              ? (spec.asset!.endsWith('.svg')
              ? SvgPicture.asset(
            spec.asset!,
            width: 60,
            height: 60,
            colorFilter: spec.iconColor != null ? ColorFilter.mode(spec.iconColor!, BlendMode.srcIn) : null,
          )
              : Image.asset(spec.asset!, width: 60, height: 60, color: spec.iconColor))
              : Icon(spec.iconData, color: spec.iconColor, size: 36),
        ),
      ),
    );
  }
}

class _PhaseHighlight extends StatefulWidget {
  final _DemoPhase phase;
  final Size frameSize;
  final VoidCallback onTap;

  const _PhaseHighlight({
    required this.phase,
    required this.frameSize,
    required this.onTap,
  });

  @override
  State<_PhaseHighlight> createState() => _PhaseHighlightState();
}

class _PhaseHighlightState extends State<_PhaseHighlight> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late List<AnimationController> _rippleControllers;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..addListener(_onPulseTick)
      ..repeat();

    _rippleControllers = [
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700)),
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700)),
    ];
  }

  double _lastPulseValue = 0;

  void _onPulseTick() {
    final v = _pulseController.value;
    if (_lastPulseValue < 0.001 && v >= 0.001) {
      HapticFeedback.lightImpact();
      _rippleControllers[0].forward(from: 0);
    }
    if (_lastPulseValue < 0.25 && v >= 0.25) {
      HapticFeedback.lightImpact();
      _rippleControllers[1].forward(from: 0);
    }
    _lastPulseValue = v;
  }

  @override
  void dispose() {
    _pulseController.removeListener(_onPulseTick);
    _pulseController.dispose();
    for (final c in _rippleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _heartbeatScale(double t) {
    if (t < 0.15) {
      final local = t / 0.15;
      return 1.0 + (Curves.easeOut.transform(local) * 0.18);
    } else if (t < 0.25) {
      final local = (t - 0.15) / 0.10;
      return 1.18 - (Curves.easeIn.transform(local) * 0.18);
    } else if (t < 0.40) {
      final local = (t - 0.25) / 0.15;
      return 1.0 + (Curves.easeOut.transform(local) * 0.14);
    } else if (t < 0.55) {
      final local = (t - 0.40) / 0.15;
      return 1.14 - (Curves.easeIn.transform(local) * 0.14);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.phase.dx * widget.frameSize.width;
    final y = widget.phase.dy * widget.frameSize.height;
    final labelTop = widget.phase.labelAbove ? y - 40 - 56 : y + 56;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          left: x - 70,
          top: y - 70,
          child: IgnorePointer(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.phase.pointerEmoji == null)
                    for (final controller in _rippleControllers)
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) => _buildRipple(controller.value),
                      ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: x - 50,
          top: y - 50,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _heartbeatScale(_pulseController.value);
                return Transform.scale(
                  scale: scale,
                  child: widget.phase.pointerEmoji != null
                      ? SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: Text(
                        widget.phase.pointerEmoji!,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  )
                      : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: (x - 90).clamp(16.0, widget.frameSize.width - 196),
          top: labelTop,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Text(
                widget.phase.label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRipple(double t) {
    if (t >= 1.0) return const SizedBox.shrink();
    final size = 80.0 + (t * 60);
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.6;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: opacity), width: 2),
      ),
    );
  }
}