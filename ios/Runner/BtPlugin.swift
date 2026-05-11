import Flutter
import AVFoundation

final class BtPlugin: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?

    static func register(with controller: FlutterViewController) {
        let channel = FlutterEventChannel(name: "com.quietly.app/bt", binaryMessenger: controller.binaryMessenger)
        let instance = BtPlugin()
        channel.setStreamHandler(instance)
        NotificationCenter.default.addObserver(instance,
            selector: #selector(routeChanged(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        sink?(BtPlugin.isBluetoothConnected())
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { sink = nil; return nil }

    @objc private func routeChanged(_ note: Notification) {
        sink?(BtPlugin.isBluetoothConnected())
    }

    static func isBluetoothConnected() -> Bool {
        for o in AVAudioSession.sharedInstance().currentRoute.outputs {
            switch o.portType {
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP: return true
            default: break
            }
        }
        return false
    }
}
