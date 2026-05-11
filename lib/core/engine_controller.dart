import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_mode.dart';
import '../services/audio_engine.dart';
import '../services/battery_monitor.dart';
import '../services/device_profiler.dart';
import '../services/error_logger.dart';

@immutable
class EngineState {
  const EngineState({
    required this.running,
    required this.mode,
    required this.recommendedMode,
    required this.latencyMs,
    required this.noiseDb,
    required this.sessionStart,
    required this.batteryDropPerHour,
    this.error,
  });

  final bool running;
  final AudioMode mode;
  final AudioMode recommendedMode;
  final int latencyMs;
  final double noiseDb;
  final DateTime? sessionStart;
  final double batteryDropPerHour;
  final String? error;

  EngineState copyWith({
    bool? running,
    AudioMode? mode,
    AudioMode? recommendedMode,
    int? latencyMs,
    double? noiseDb,
    DateTime? sessionStart,
    bool clearSessionStart = false,
    double? batteryDropPerHour,
    String? error,
    bool clearError = false,
  }) {
    return EngineState(
      running: running ?? this.running,
      mode: mode ?? this.mode,
      recommendedMode: recommendedMode ?? this.recommendedMode,
      latencyMs: latencyMs ?? this.latencyMs,
      noiseDb: noiseDb ?? this.noiseDb,
      sessionStart: clearSessionStart ? null : (sessionStart ?? this.sessionStart),
      batteryDropPerHour: batteryDropPerHour ?? this.batteryDropPerHour,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const EngineState initial = EngineState(
    running: false,
    mode: AudioMode.anc,
    recommendedMode: AudioMode.anc,
    latencyMs: 0,
    noiseDb: -60.0,
    sessionStart: null,
    batteryDropPerHour: 0,
  );
}

class EngineController extends StateNotifier<EngineState> {
  EngineController({
    required AudioEngine engine,
    required BatteryMonitor battery,
    required DeviceProfiler profiler,
    required SharedPreferences prefs,
  })  : _engine = engine,
        _battery = battery,
        _profiler = profiler,
        _prefs = prefs,
        super(EngineState.initial) {
    _bootstrap();
  }

  final AudioEngine _engine;
  final BatteryMonitor _battery;
  final DeviceProfiler _profiler;
  final SharedPreferences _prefs;

  StreamSubscription<EngineMetrics>? _metricsSub;
  StreamSubscription<double>? _batterySub;

  Future<void> _bootstrap() async {
    final AudioMode recommended = await _profiler.recommend();
    final String? saved = _prefs.getString('mode');
    final AudioMode mode = saved != null
        ? AudioMode.values.firstWhere(
            (AudioMode m) => m.id == saved,
            orElse: () => recommended,
          )
        : recommended;
    state = state.copyWith(mode: mode, recommendedMode: recommended);

    _metricsSub = _engine.metrics.listen((EngineMetrics m) {
      state = state.copyWith(latencyMs: m.latencyMs, noiseDb: m.noiseDb);
    });

    _batterySub = _battery.dropPerHourStream().listen((double drop) {
      state = state.copyWith(batteryDropPerHour: drop);
      if (drop > 8 && state.mode != AudioMode.powerSaver && state.running) {
        switchMode(AudioMode.powerSaver, auto: true);
      }
    });
  }

  Future<void> start() async {
    try {
      await _engine.start(state.mode);
      state = state.copyWith(running: true, sessionStart: DateTime.now(), clearError: true);
    } catch (e, st) {
      ErrorLogger.log('start', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
      state = state.copyWith(running: false, clearSessionStart: true);
    } catch (e, st) {
      ErrorLogger.log('stop', e, st);
    }
  }

  Future<void> toggle() => state.running ? stop() : start();

  Future<void> switchMode(AudioMode m, {bool auto = false}) async {
    state = state.copyWith(mode: m);
    await _prefs.setString('mode', m.id);
    if (state.running) {
      await _engine.applyMode(m);
    }
  }

  @override
  void dispose() {
    _metricsSub?.cancel();
    _batterySub?.cancel();
    super.dispose();
  }
}
