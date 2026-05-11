import 'package:flutter_test/flutter_test.dart';
import 'package:quietly/services/device_profiler.dart';

void main() {
  test('high score → ANC', () {
    final s = DeviceProfiler.scoreFor(cores: 8, ramMb: 8000, year: 2024);
    expect(s, greaterThanOrEqualTo(7000));
  });

  test('low score → warning', () {
    final s = DeviceProfiler.scoreFor(cores: 4, ramMb: 2000, year: 2017);
    expect(s, lessThan(4500));
  });
}
