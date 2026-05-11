enum AudioMode {
  anc(
    id: 'anc',
    fftSize: 1024,
    sampleRate: 48000,
    strength: 1.0,
    targetLatencyMs: 35,
  ),
  powerSaver(
    id: 'power',
    fftSize: 512,
    sampleRate: 32000,
    strength: 0.55,
    targetLatencyMs: 60,
  ),
  transparency(
    id: 'transparency',
    fftSize: 256,
    sampleRate: 32000,
    strength: 0.0,
    targetLatencyMs: 25,
  );

  const AudioMode({
    required this.id,
    required this.fftSize,
    required this.sampleRate,
    required this.strength,
    required this.targetLatencyMs,
  });

  final String id;
  final int fftSize;
  final int sampleRate;
  final double strength;
  final int targetLatencyMs;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'fftSize': fftSize,
        'sampleRate': sampleRate,
        'strength': strength,
      };
}

enum EqPreset {
  call('call', 200, 3000, 4000),
  music('music', 80, 1000, 14000),
  movie('movie', 60, 2500, 12000);

  const EqPreset(this.id, this.hpHz, this.midHz, this.lpHz);
  final String id;
  final int hpHz;
  final int midHz;
  final int lpHz;
}
