// lib/features/wheel/widgets/paste_list_tutorial_overlay.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widget/sparkle_burst_button.dart';

class PasteListTutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const PasteListTutorialOverlay({super.key, required this.onDismiss});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => PasteListTutorialOverlay(
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<PasteListTutorialOverlay> createState() => _PasteListTutorialOverlayState();
}

class _PasteListTutorialOverlayState extends State<PasteListTutorialOverlay> {
  static const _lines = ['Read 1 Chapter', 'Clean Room', 'Call my Mom'];
  String _displayText = '';
  bool _showAddAll = false;
  Timer? _timer;
  final _iconKey = GlobalKey<_TutorialAddIconState>(); // 👈 lets the auto-loop trigger presses on the icon widget below

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  Future<void> _typeLine(String text) async {
    final words = text.split(' ');
    for (int w = 0; w < words.length; w++) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final word = words[w];
      for (int i = 0; i < word.length; i++) {
        if (!mounted) return;
        setState(() => _displayText += word[i]);
        await _wait(70);
      }
      if (w < words.length - 1) {
        if (!mounted) return;
        setState(() => _displayText += ' ');
        await _wait(70);
      }
    }
  }

  Future<void> _runAnimation() async {
    while (mounted) {
      setState(() {
        _displayText = '';
        _showAddAll = false;
      });
      await _wait(600);
      if (!mounted) return;
      for (int i = 0; i < _lines.length; i++) {
        await _typeLine(_lines[i]);
        if (!mounted) return;
        if (i < _lines.length - 1) {
          setState(() => _displayText += '\n\n');
          await _wait(500);
        }
      }
      if (!mounted) return;
      await _wait(500);
      setState(() => _showAddAll = true);
      await _loopIconPress(); // 👈 replaces the old flat `await _wait(1800)`
    }
  }

  Future<void> _loopIconPress() async {
    while (mounted && _showAddAll) {
      _iconKey.currentState?.press();
      await _wait(900);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paste a whole list at once!',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Each line becomes its own entry',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 90),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _displayText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showAddAll ? 1.0 : 0.0,
                  child: Align(
                    alignment: Alignment.center,
                    child: _TutorialAddIcon(key: _iconKey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onDismiss();
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Center(
                    child: Text('☝', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 👇 small dedicated widget — owns the press-bounce animation, wraps SparkleBurstButton for the burst
class _TutorialAddIcon extends StatefulWidget {
  const _TutorialAddIcon({super.key});

  @override
  State<_TutorialAddIcon> createState() => _TutorialAddIconState();
}

class _TutorialAddIconState extends State<_TutorialAddIcon> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scale;
  final _sparkleKey = GlobalKey<SparkleBurstButtonState>();

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
    ]).animate(_pressController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  // 👇 called both by direct taps (via SparkleBurstButton's onTap) and the tutorial's auto-loop
  void press() {
    _pressController.forward(from: 0);
    _sparkleKey.currentState?.fire();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: SparkleBurstButton(
        key: _sparkleKey,
        onTap: () => _pressController.forward(from: 0), // sparkle already fires itself; just add the bounce
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF6B6B6B), size: 16),
          ),
        ),
      ),
    );
  }
}