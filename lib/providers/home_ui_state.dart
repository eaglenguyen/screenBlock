import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_ui_state.g.dart';

@Riverpod(keepAlive: true) // 👈 survives navigation, since it's never autoDisposed
class QuickBlocksExpanded extends _$QuickBlocksExpanded {
  @override
  bool build() => true; // 👈 default: expanded

  void toggle() => state = !state;
  void set(bool value) => state = value;
}