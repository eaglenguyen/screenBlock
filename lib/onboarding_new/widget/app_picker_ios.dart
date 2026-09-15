import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmbeddedAppPicker extends StatefulWidget {
  final String saveKey;
  final ValueChanged<int> onCountChanged;

  const EmbeddedAppPicker({
    super.key,
    required this.saveKey,
    required this.onCountChanged,
  });

  @override
  State<EmbeddedAppPicker> createState() => _EmbeddedAppPickerState();
}

class _EmbeddedAppPickerState extends State<EmbeddedAppPicker> {
  int? _viewId;
  StreamSubscription? _sub;

  void _onPlatformViewCreated(int id) {
    _viewId = id;
    final channel = EventChannel('com.eagle.pausenow/embedded_app_picker_events_$id');
    _sub = channel.receiveBroadcastStream().listen((count) {
      widget.onCountChanged(count as int);
    }, onError: (e) {
      debugPrint('❌ embedded app picker stream error: $e');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'com.eagle.pausenow/embedded_app_picker_view',
      creationParams: {'saveKey': widget.saveKey},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}