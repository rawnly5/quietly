import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_mode.dart';
import '../services/audio_engine.dart';
import '../services/battery_monitor.dart';
import '../services/bt_watcher.dart';
import '../services/device_profiler.dart';
import '../services/iap_service.dart';
import '../services/permission_service.dart';
import 'engine_controller.dart';

final Provider<SharedPreferences> sharedPrefsProvider =
    Provider<SharedPreferences>((Ref ref) => throw UnimplementedError());

final Provider<AudioEngine> audioEngineProvider =
    Provider<AudioEngine>((Ref ref) => AudioEngine());

final Provider<PermissionService> permissionServiceProvider =
    Provider<PermissionService>((Ref ref) => PermissionService());

final Provider<DeviceProfiler> deviceProfilerProvider =
    Provider<DeviceProfiler>((Ref ref) => DeviceProfiler());

final Provider<IapService> iapServiceProvider =
    Provider<IapService>((Ref ref) => IapService(ref.watch(sharedPrefsProvider)));

final Provider<BatteryMonitor> batteryMonitorProvider =
    Provider<BatteryMonitor>((Ref ref) => BatteryMonitor());

final Provider<BtWatcher> btWatcherProvider =
    Provider<BtWatcher>((Ref ref) => BtWatcher());

final StateNotifierProvider<EngineController, EngineState> engineControllerProvider =
    StateNotifierProvider<EngineController, EngineState>((Ref ref) {
  return EngineController(
    engine: ref.watch(audioEngineProvider),
    battery: ref.watch(batteryMonitorProvider),
    profiler: ref.watch(deviceProfilerProvider),
    prefs: ref.watch(sharedPrefsProvider),
  );
});

final Provider<AudioMode> recommendedModeProvider = Provider<AudioMode>((Ref ref) {
  return ref.watch(engineControllerProvider).recommendedMode;
});
