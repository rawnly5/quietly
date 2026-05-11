import 'package:flutter_test/flutter_test.dart';
import 'package:quietly/services/device_profiler.dart';

void main() {
  test('profiler creates expected capability shape', () async {
    final p = DeviceProfiler();
    final cap = await p.probe();
    expect(cap.score, greaterThanOrEqualTo(0));
    expect(cap.recommended, isA<AudioMode>());
    expect(cap.weak, isA<bool>());
  });

  test('recommend returns a valid AudioMode', () async {
    final p = DeviceProfiler();
    final mode = await p.recommend();
    expect(mode, isA<AudioMode>());
  });
}