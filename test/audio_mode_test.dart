import 'package:flutter_test/flutter_test.dart';
import 'package:quietly/models/audio_mode.dart';

void main() {
  group('AudioMode', () {
    test('toMap contains required keys', () {
      final Map<String, dynamic> m = AudioMode.anc.toMap();
      expect(m['id'], 'anc');
      expect(m['sampleRate'], 48000);
      expect(m['fftSize'], 1024);
      expect(m['strength'], 1.0);
    });

    test('powerSaver is lighter than anc', () {
      expect(AudioMode.powerSaver.sampleRate, lessThan(AudioMode.anc.sampleRate));
      expect(AudioMode.powerSaver.fftSize, lessThan(AudioMode.anc.fftSize));
    });

    test('transparency disables subtraction', () {
      expect(AudioMode.transparency.strength, 0.0);
    });
  });

  group('EqPreset', () {
    test('call preset cuts low rumble', () {
      expect(EqPreset.call.hpHz, greaterThan(EqPreset.music.hpHz));
    });
  });
}
