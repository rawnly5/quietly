import 'dart:async';

import 'package:flutter/services.dart';

class BtWatcher {
  static const EventChannel _channel = EventChannel('com.quietly.app/bt');
  Stream<bool> connectedStream() => _channel
      .receiveBroadcastStream()
      .map<bool>((dynamic e) => e == true);
}
