import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class MascotCharacter extends StatefulWidget {
  final double size;
  final String rivFile;

  const MascotCharacter({
    super.key,
    this.size = 140,
    this.rivFile = 'assets/rive/mr_square_hii.riv',

  });

  @override
  State<MascotCharacter> createState() => _MascotCharacterState();
}

class _MascotCharacterState extends State<MascotCharacter> {
  FileLoader? _fileLoader;


  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      widget.rivFile, // 👈 use the parameter
      riveFactory: Factory.flutter,
    );
  }

  RiveWidgetController? _controller;

  @override
  void dispose() {
    _fileLoader?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader!,
        builder: (context, state) => switch (state) {
          RiveLoading() => const SizedBox(),
          RiveFailed() => const SizedBox(),
          RiveLoaded() => RiveWidget(
            controller: _controller ??= RiveWidgetController(state.file),
            fit: Fit.contain,
          ),
        },
      ),
    );
  }
}