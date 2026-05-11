import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await notif.initialize(const InitializationSettings(android: android));
    final FlutterBackgroundService svc = FlutterBackgroundService();
    await svc.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'quietly_anc',
        initialNotificationTitle: 'Quietly',
        initialNotificationContent: 'Isolating noise',
        foregroundServiceNotificationId: 4242,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  static void _onStart(ServiceInstance svc) {}
}
