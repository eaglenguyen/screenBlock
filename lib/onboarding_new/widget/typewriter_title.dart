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
  final Map<String, Color>? highlightWords; // 👈 new — maps a substring to a highlight color



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
    this.highlightWords, // 👈 new

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
    if (oldWidget.text != widget.text) {
      setState(() => _displayText = '');
      _type();
    }
  }

  Future<void> _type() async {
    await Future.delayed(widget.startDelay);
    final chars = widget.text.characters.toList();
    for (int i = 0; i < chars.length; i++) {
      if (!mounted) return;
      if (widget.haptics) HapticFeedback.lightImpact();
      setState(() => _displayText = chars.sublist(0, i + 1).join());
      await Future.delayed(widget.letterDelay);
    }
  }

  List<TextSpan> _buildSpans() { // 👈 new — splits _displayText into colored/uncolored spans
    if (widget.highlightWords == null || widget.highlightWords!.isEmpty) {
      return [TextSpan(text: _displayText)];
    }

    final spans = <TextSpan>[];
    int cursor = 0;
    final text = _displayText;

    while (cursor < text.length) {
      int? matchStart;
      int? matchEnd;
      Color? matchColor;

      for (final entry in widget.highlightWords!.entries) {
        final index = text.indexOf(entry.key, cursor);
        if (index == cursor) {
          matchStart = index;
          matchEnd = index + entry.key.length;
          matchColor = entry.value;
          break;
        }
      }

      if (matchStart != null && matchEnd != null) {
        spans.add(TextSpan(text: text.substring(matchStart, matchEnd), style: TextStyle(color: matchColor)));
        cursor = matchEnd;
      } else {
        // find the next match position to know how far plain text extends
        int nextMatch = text.length;
        for (final key in widget.highlightWords!.keys) {
          final idx = text.indexOf(key, cursor);
          if (idx != -1 && idx < nextMatch) nextMatch = idx;
        }
        spans.add(TextSpan(text: text.substring(cursor, nextMatch)));
        cursor = nextMatch;
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.poppins(
            color: widget.color,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            height: widget.height,
          ),
          children: _buildSpans(),
        ),
        textAlign: widget.textAlign,
      ),
    );
  }
}