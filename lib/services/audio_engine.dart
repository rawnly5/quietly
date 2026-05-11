import 'dart:async';

import 'package:flutter/services.dart';

import '../models/audio_mode.dart';

class EngineMetrics {
  const EngineMetrics({required this.latencyMs, required this.noiseDb});
  final int latencyMs;
  final double noiseDb;
}

class AudioEngine {
  AudioEngine() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const MethodChannel _channel = MethodChannel('com.quietly.app/audio');
  static const EventChannel _events = EventChannel('com.quietly.app/audio.events');

  final StreamController<EngineMetrics> _metricsCtrl =
      StreamController<EngineMetrics>.broadcast();
  StreamSubscription<dynamic>? _eventSub;

  Stream<EngineMetrics> get metrics => _metricsCtrl.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'metrics') {
      final Map<dynamic, dynamic> a = call.arguments as Map<dynamic, dynamic>;
      _metricsCtrl.add(EngineMetrics(
        latencyMs: (a['latencyMs'] as num).toInt(),
        noiseDb: (a['noiseDb'] as num).toDouble(),
      ));
    }
  }

  Future<void> start(AudioMode mode) async {
    _eventSub ??= _events.receiveBroadcastStream().listen((dynamic e) {
      if (e is Map) {
        _metricsCtrl.add(EngineMetrics(
          latencyMs: ((e['latencyMs'] as num?) ?? 0).toInt(),
          noiseDb: ((e['noiseDb'] as num?) ?? -60).toDouble(),
        ));
      }
    });
    await _channel.invokeMethod<void>('start', mode.toMap());
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
    await _eventSub?.cancel();
    _eventSub = null;
  }

  Future<void> applyMode(AudioMode mode) =>
      _channel.invokeMethod<void>('applyMode', mode.toMap());

  Future<int> measureLatency() async {
    final int ms = (await _channel.invokeMethod<int>('latency')) ?? 0;
    return ms;
  }

  Future<void> setEqPreset(EqPreset preset) =>
      _channel.invokeMethod<void>('setEq', <String, dynamic>{
        'hp': preset.hpHz,
        'mid': preset.midHz,
        'lp': preset.lpHz,
      });
}
