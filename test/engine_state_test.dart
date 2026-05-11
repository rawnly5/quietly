import 'package:flutter_test/flutter_test.dart';
import 'package:quietly/core/engine_controller.dart';
import 'package:quietly/models/audio_mode.dart';

void main() {
  test('initial state', () {
    expect(EngineState.initial.running, false);
    expect(EngineState.initial.mode, AudioMode.anc);
  });

  test('copyWith clearSessionStart', () {
    final EngineState s = EngineState.initial.copyWith(sessionStart: DateTime.now());
    expect(s.sessionStart, isNotNull);
    final EngineState s2 = s.copyWith(clearSessionStart: true);
    expect(s2.sessionStart, isNull);
  });
}
