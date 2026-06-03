import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../features/home/widgets/xp_float_label.dart';

class XpAnimation {
  XpAnimation._();
  static final instance = XpAnimation._();

  OverlayEntry? _overlayEntry;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioLoaded = false;

  Future<void> init() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/levelUp.mp3');
      _audioLoaded = true;
    } catch (e) {
      debugPrint('❌ XpAnimationService audio init error: $e');
    }
  }

  Future<void> showXpGain({
    required OverlayState overlay, // 👈 change from BuildContext
    required GlobalKey xpBadgeKey,
    required int xpAmount,
  }) async {

    final renderBox = xpBadgeKey.currentContext
        ?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    final size = renderBox.size;

    final startPos = Offset(
      position.dx + size.width / 2,
      position.dy,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => XpFloatLabel(
        xpAmount: xpAmount,
        startPosition: startPos,
        onComplete: _removeOverlay,
      ),
    );

    overlay.insert(_overlayEntry!);

    if (_audioLoaded) {
      try {
        await _audioPlayer.seek(Duration.zero);
        unawaited(_audioPlayer.play()); // 👈 don't await — fire and forget
      } catch (e) {
        debugPrint('❌ coin sound error: $e');
      }
    }



  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}