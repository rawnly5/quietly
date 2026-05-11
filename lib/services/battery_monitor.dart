import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

class BatteryMonitor {
  final Battery _battery = Battery();
  Timer? _timer;
  int? _baseLevel;
  DateTime? _baseTime;

  Stream<double> dropPerHourStream() async* {
    final StreamController<double> ctrl = StreamController<double>();
    Timer.periodic(const Duration(minutes: 5), (_) async {
      final int level = await _battery.batteryLevel;
      final DateTime now = DateTime.now();
      _baseLevel ??= level;
      _baseTime ??= now;
      final double hours =
          now.difference(_baseTime!).inSeconds / 3600.0;
      if (hours > 0.05) {
        final double drop = (_baseLevel! - level) / hours;
        ctrl.add(drop);
      }
    });
    yield* ctrl.stream;
  }
}
