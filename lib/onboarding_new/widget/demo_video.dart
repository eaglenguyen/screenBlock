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
// Coach mark style demo
class _DemoPhase {
  final Duration pauseAt;
  final double dx; // 0.0-1.0, horizontal position within the fullscreen frame
  final double dy; // 0.0-1.0, vertical position within the fullscreen frame
  final String label;
  final bool labelAbove; // 👈 new
  final String? pointerEmoji; // 👈 new — if set, renders this emoji instead of the plain circle



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
  bool _showCloseButton = false; // 👈 new
  bool _videoEnded = false; // 👈 new


  late AnimationController _iconController;
  late AnimationController _expandController;
  bool _isExpanding = false;
  Rect? _phoneStartRect; // 👈 new — the phone's real on-screen position/size, captured right before expanding

  final GlobalKey _phoneKey = GlobalKey(); // 👈 new

  final _icons = const [
    _IconSpec(fromLeft: true, asset: 'assets/icons/instagram.png', targetX: -140, targetY: -100, delay: 0.0),
    _IconSpec(fromLeft: true, asset: 'assets/icons/youtube.png', targetX: -148, targetY: 70, delay: 0.15),
    _IconSpec(fromLeft: false, asset: 'assets/icons/twitter.png', targetX: 140, targetY: -120, delay: 0.05),
    _IconSpec(fromLeft: false, asset: 'assets/icons/tiktok.png', targetX: 148, targetY: 20, delay: 0.2),
  ];

  // 👇 PLACEHOLDER TIMESTAMPS/POSITIONS — replace with real values from your actual recorded video
  final _phases = const [
    _DemoPhase(pauseAt: Duration(seconds: 1, milliseconds: 200), dx: 0.81, dy: 0.60, label: 'Tap to block'),
    _DemoPhase(pauseAt: Duration(seconds: 4, milliseconds: 300), dx: 0.5, dy: 0.89, label: 'Tap Spin', labelAbove: true, pointerEmoji: '👇'),
    _DemoPhase(pauseAt: Duration(seconds: 7), dx: 0.5, dy: 0.15, label: 'Tap the notification', pointerEmoji: '👆'),
    _DemoPhase(pauseAt: Duration(seconds: 9 , milliseconds: 200), dx: 0.5, dy: 0.415, label: 'Spin the wheel!'),
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

    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _videoController = VideoPlayerController.asset('assets/video/demowheel.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoInitialized = true);
        _videoController.setLooping(false); // 👈 fixed — was true
        _videoController.addListener(_checkPhaseProgress); // 👈 fixed — was missing entirely
        _videoController.addListener(_checkVideoEnded); // 👈 new

      }).catchError((e) {
        debugPrint('❌ video init error: $e');
      });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _expandController.dispose();
    _videoController.removeListener(_checkPhaseProgress);
    _videoController.removeListener(_checkVideoEnded); // 👈 new

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

  void _checkVideoEnded() { // 👈 new
    if (_videoEnded) return;
    final value = _videoController.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _videoEnded = true;
      setState(() => _showCloseButton = true); // 👈 close button now only appears here
      widget.onContinue(); // 👈 removed the Future.delayed entirely — advances immediately

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

    _iconController.reverse();
    await _expandController.forward();

    if (!mounted) return;
    _videoController.seekTo(Duration.zero);
    _videoController.play(); // 👈 this is now the ONLY place the video ever starts playing
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const phoneWidth = 250.0;
    final videoAspect = _videoInitialized ? _videoController.value.aspectRatio : (9 / 19.5); // fallback guess until video loads
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
                          const TypewriterTitle(text: 'Awesome 🎉', fontSize: 26),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the phone to preview, then see the full flow.',
                            style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15),
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
                          children: [                    Opacity(
                            opacity: _isExpanding ? 0.0 : 1.0,
                            child: Container( // 👈 was GestureDetector — no more tap-to-play here
                              key: _phoneKey,
                              width: phoneWidth,
                              height: phoneHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: const Color(0xFF4A3728), width: 3),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: _videoInitialized
                                    ? AspectRatio(
                                  aspectRatio: _videoController.value.aspectRatio,
                                  child: VideoPlayer(_videoController), // 👈 just shows the first frame, paused, no play button overlay
                                )
                                    : const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3B0))),
                              ),
                            ),
                          ),
                            AnimatedBuilder(
                              animation: _iconController,
                              builder: (context, _) {
                                return Opacity(
                                  opacity: _isExpanding ? 0.0 : 1.0,
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
                final t = Curves.easeOutCubic.transform(_expandController.value); // 👈 was easeInOutCubic — a curve with a gentler middle-phase rate of change
                final start = _phoneStartRect!;
                final end = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
                final rect = Rect.lerp(start, end, t)!;
                final radius = lerpDouble(32, 0, t)!;

                return Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        children: [
                          _videoInitialized
                              ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          )
                              : const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3B0))),
                          if (_showingPhaseOverlay && t > 0.98 && _currentPhaseIndex < _phases.length)
                            _PhaseHighlight(
                              phase: _phases[_currentPhaseIndex],
                              frameSize: rect.size,
                              onTap: _onPhaseTapped,
                            ),
                        ],
                      ),
                    ),
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
  late List<AnimationController> _rippleControllers; // 👈 new — one-shot controllers, triggered on demand

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..addListener(_onPulseTick)
      ..repeat();

    // 👇 new — two ripple controllers, each fires once per trigger, one per heartbeat peak
    _rippleControllers = [
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700)),
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700)),
    ];
  }

  double _lastPulseValue = 0;

  void _onPulseTick() {
    final v = _pulseController.value;
    if (_lastPulseValue < 0.001 && v >= 0.001) { // 👈 changed — fires at the very START of the beat (t≈0), not at the peak (t=0.15)
      HapticFeedback.lightImpact();
      _rippleControllers[0].forward(from: 0);
    }
    if (_lastPulseValue < 0.25 && v >= 0.25) { // 👈 changed — start of second beat's scale-up (was 0.4, its peak)
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
      c.dispose(); // 👈 new
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
                  if (widget.phase.pointerEmoji == null) // 👈 new — only show ripples when there's no pointer emoji
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
          left: x - 40,
          top: y - 40,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _heartbeatScale(_pulseController.value);
                return Transform.scale(
                  scale: scale,
                  child: widget.phase.pointerEmoji != null
                      ? SizedBox( // 👈 new — emoji version, same 80x80 footprint as the circle for consistent positioning
                    width: 80,
                    height: 80,
                    child: Center(
                      child: Text(
                        widget.phase.pointerEmoji!,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  )
                  : Container(
                    width: 80,
                    height: 80,
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
    if (t >= 1.0) return const SizedBox.shrink(); // 👈 new — fully hidden once its one-shot animation completes
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