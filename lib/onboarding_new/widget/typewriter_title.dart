// lib/onboarding_new/widget/typewriter_title.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// 👈 new import
class TypewriterTitle extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double height;
  final Duration letterDelay;
  final bool haptics;
  final TextAlign textAlign; // 👈 new
  final Duration startDelay; // 👈 new



  const TypewriterTitle({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w800,
    this.color = const Color(0xFF4A3728),
    this.height = 1.25,
    this.letterDelay = const Duration(milliseconds: 35),
    this.haptics = true,
    this.textAlign = TextAlign.left,
    this.startDelay = const Duration(milliseconds: 400), // 👈 new — matches/slightly exceeds your screen transition's 600ms duration once you account for the fade curve settling

  });

  @override
  State<TypewriterTitle> createState() => _TypewriterTitleState();
}

class _TypewriterTitleState extends State<TypewriterTitle> {
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _type();
  }

  @override
  void didUpdateWidget(covariant TypewriterTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 👇 re-types if the title itself changes (e.g. swapping screens while reusing the same widget instance)
    if (oldWidget.text != widget.text) {
      setState(() => _displayText = '');
      _type();
    }
  }

  Future<void> _type() async {
    await Future.delayed(widget.startDelay);
    final chars = widget.text.characters.toList(); // 👈 new — splits into real grapheme clusters, emoji included as single units
    for (int i = 0; i < chars.length; i++) { // 👈 was widget.text.length
      if (!mounted) return;
      if (widget.haptics) HapticFeedback.lightImpact();
      setState(() => _displayText = chars.sublist(0, i + 1).join()); // 👈 was widget.text.substring(0, i + 1)
      await Future.delayed(widget.letterDelay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox( // 👈 new — forces full width so textAlign has something to center within
      width: double.infinity,
      child: Text(
        _displayText,
        textAlign: widget.textAlign,
        style: GoogleFonts.poppins(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          height: widget.height,
        ),
      ),
    );
  }
}