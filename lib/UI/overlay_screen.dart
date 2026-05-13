import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen>
    with TickerProviderStateMixin {

  static const _blockChannel = MethodChannel(
    'com.example.screenblock/block',
  );

  // ── Animation controllers ────────────────────────
  late final AnimationController _blobController;
  late final Animation<double> _blobScale;
  late final Animation<double> _blobBorderRadius;

  // ── Countdown state ──────────────────────────────
  int _countdown = 5;
  bool _countdownComplete = false;
  Timer? _countdownTimer;

  // ── Breathing text state ─────────────────────────
  int _breatheIndex = 0;
  Timer? _breatheTimer;

  final List<String> _breatheCycle = [
    'Breathe in',
    'Hold',
    'Breathe out',
  ];

  final List<int> _breatheDurations = [4000, 7000, 8000];

  @override
  void initState() {
    super.initState();
    _setupBlobAnimation();
    _startCountdown();
    _startBreatheTimer();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _blobController.dispose();
    _countdownTimer?.cancel();
    _breatheTimer?.cancel();
    super.dispose();
  }

  // ── Blob animation ───────────────────────────────
  void _setupBlobAnimation() {
    _blobController = AnimationController(
      vsync: this,
      // 4 + 7 + 8 = 19 seconds full cycle
      duration: const Duration(seconds: 19),
    )..repeat();

    // expand during inhale (0-4s = 0.0-0.21 of cycle)
    // hold at full size (4-11s = 0.21-0.58 of cycle)
    // contract during exhale (11-19s = 0.58-1.0 of cycle)
    _blobScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.15) // 👈 wider range — was 1.0 to 1.1
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.15),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.85) // 👈 contracts smaller than start
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
    ]).animate(_blobController);

    _blobBorderRadius = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 40.0, end: 28.0) // 👈 was 60→45, now sharper corners
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween(28.0),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 28.0, end: 40.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
    ]).animate(_blobController);
  }

  // ── Countdown ────────────────────────────────────
  void _startCountdown() {
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
          } else {
            _countdown = 0;
            _countdownComplete = true;
            timer.cancel();
            HapticFeedback.lightImpact();
          }
        });
      },
    );
  }

  // ── Breathing text ───────────────────────────────
  void _startBreatheTimer() {
    _scheduleBreathe();
  }

  void _scheduleBreathe() {
    _breatheTimer = Timer(
      Duration(milliseconds: _breatheDurations[_breatheIndex]),
          () {
        if (!mounted) return;
        setState(() {
          _breatheIndex =
              (_breatheIndex + 1) % _breatheCycle.length;
        });
        _scheduleBreathe();
      },
    );
  }

  // ── Actions ──────────────────────────────────────
  Future<void> _dontOpen() async {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    await _blockChannel.invokeMethod('goHome');
  }

  Future<void> _openApp() async {
    if (!_countdownComplete) return;
    HapticFeedback.lightImpact();
    await _blockChannel.invokeMethod('dismissBlockScreen');
  }

  // ── Build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildBlob()),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFF2A2A48),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFEDB82A),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Time limit reached',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Blob ─────────────────────────────────────────
  Widget _buildBlob() {
    return Center(
      child: AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) {
          final r = _blobBorderRadius.value;
          return Transform.scale(
            scale: _blobScale.value,
            child: Container(
              width: 330,   // 👈 narrower
              height: 500,  // 👈 taller — more rectangular
              decoration: BoxDecoration(
                color: const Color(0xFFCFB96E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(r + 8),
                  topRight: Radius.circular(r - 8),
                  bottomLeft: Radius.circular(r - 8),
                  bottomRight: Radius.circular(r + 8),
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    _breatheCycle[_breatheIndex],
                    key: ValueKey(_breatheIndex),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1208),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Buttons ──────────────────────────────────────
  Widget _buildButtons() {
    return Column(
      children: [
        _buildDontOpenButton(),
        const SizedBox(height: 10),
        _buildCountdownButton(),
      ],
    );
  }

  Widget _buildDontOpenButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _dontOpen,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(
            side: BorderSide(
              color: Color(0xFF2A2A48),
              width: 0.5,
            ),
          ),
        ),
        child: const Text(
          "Don't open",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: _countdownComplete
                ? const Color(0xFFEDB82A)
                : const Color(0xFF2A2A48),
            width: 0.5,
          ),
        ),
        child: TextButton(
          onPressed: _countdownComplete ? _openApp : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const StadiumBorder(),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _countdownComplete
                  ? const Color(0xFFEDB82A)
                  : const Color(0xFF7070A0),
            ),
            child: Text(
              _countdownComplete
                  ? 'Open app'
                  : 'Open in ${_countdown}s',
            ),
          ),
        ),
      ),
    );
  }
}