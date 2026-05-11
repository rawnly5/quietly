import 'package:permission_handler/permission_handler.dart';

class PermissionResult {
  const PermissionResult({required this.mic, required this.notification});
  final bool mic;
  final bool notification;
  bool get allGranted => mic && notification;
}

class PermissionService {
  Future<PermissionResult> request() async {
    final Map<Permission, PermissionStatus> r = await <Permission>[
      Permission.microphone,
      Permission.notification,
    ].request();
    return PermissionResult(
      mic: r[Permission.microphone]?.isGranted ?? false,
      notification: r[Permission.notification]?.isGranted ?? false,
    );
  }

  Future<bool> hasMic() async => Permission.microphone.isGranted;
}
