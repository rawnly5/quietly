import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../models/audio_mode.dart';

class DeviceCapability {
  const DeviceCapability({required this.score, required this.recommended, required this.weak});
  final int score;
  final AudioMode recommended;
  final bool weak;
}

class DeviceProfiler {
  Future<DeviceCapability> probe() async {
    final DeviceInfoPlugin info = DeviceInfoPlugin();
    int score = 50;
    if (Platform.isAndroid) {
      final AndroidDeviceInfo a = await info.androidInfo;
      final int sdk = a.version.sdkInt;
      score = 30 + (sdk - 23).clamp(0, 15) * 3;
      if (a.isPhysicalDevice == false) score -= 20;
    } else if (Platform.isIOS) {
      final IosDeviceInfo i = await info.iosInfo;
      score = i.isPhysicalDevice ? 85 : 40;
    }
    final AudioMode rec = score >= 70
        ? AudioMode.anc
        : score >= 45
            ? AudioMode.powerSaver
            : AudioMode.transparency;
    return DeviceCapability(score: score, recommended: rec, weak: score < 45);
  }

  Future<AudioMode> recommend() async => (await probe()).recommended;
}
