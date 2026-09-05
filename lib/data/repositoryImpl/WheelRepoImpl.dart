import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';

class WheelRepository {
  Box get _box => Hive.box(HiveBoxNames.settings);

  List<String> getItems() {
    return List<String>.from(_box.get('wheelItems', defaultValue: <String>[]));
  }

  Future<void> saveItems(List<String> items) async {
    await _box.put('wheelItems', items);
  }
}