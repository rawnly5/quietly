import Flutter
import AVFoundation

/// Bridges Flutter <-> AVAudioEngine. Implements:
///  - playAndRecord session w/ allowBluetoothA2DP + measureMode
///  - voiceProcessing input (iOS built-in echo cancel + noise suppression)
///  - per-mode EQ (HP / parametric / LP) via AVAudioUnitEQ
///  - latency + noise level metrics emitted to Dart via EventChannel
final class AudioEnginePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    static var shared: AudioEnginePlugin?

    private let engine = AVAudioEngine()
    private let eq = AVAudioUnitEQ(numberOfBands: 3)
    private var eventSink: FlutterEventSink?
    private var lastLatencyMs: Int = 0
    private var strength: Float = 1.0

    static func register(with controller: FlutterViewController) {
        let methods = FlutterMethodChannel(name: "com.quietly.app/audio", binaryMessenger: controller.binaryMessenger)
        let events  = FlutterEventChannel(name: "com.quietly.app/audio.events", binaryMessenger: controller.binaryMessenger)
        let instance = AudioEnginePlugin()
        shared = instance
        methods.setMethodCallHandler { call, result in instance.handle(call, result: result) }
        events.setStreamHandler(instance)
    }

    static func register(with registrar: FlutterPluginRegistrar) {}

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "start":
                let args = call.arguments as? [String: Any] ?? [:]
                let sr = (args["sampleRate"] as? Int) ?? 48000
                strength = Float((args["strength"] as? Double) ?? 1.0)
                try start(sampleRate: Double(sr))
                result(nil)
            case "stop":
                stop(); result(nil)
            case "applyMode":
                let args = call.arguments as? [String: Any] ?? [:]
                strength = Float((args["strength"] as? Double) ?? 1.0)
                result(nil)
            case "latency":
                result(lastLatencyMs)
            case "setEq":
                let args = call.arguments as? [String: Any] ?? [:]
                applyEq(hp: (args["hp"] as? Int) ?? 80,
                        mid: (args["mid"] as? Int) ?? 1000,
                        lp: (args["lp"] as? Int) ?? 14000)
                result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        } catch { result(FlutterError(code: "ENGINE", message: error.localizedDescription, details: nil)) }
    }

    private func start(sampleRate: Double) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothA2DP, .allowBluetooth, .defaultToSpeaker, .mixWithOthers])
        try session.setPreferredSampleRate(sampleRate)
        try session.setPreferredIOBufferDuration(0.010)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        try engine.inputNode.setVoiceProcessingEnabled(true)

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        engine.attach(eq)
        engine.connect(input, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.emitMetrics(buffer: buffer)
        }

        engine.prepare()
        try engine.start()
        lastLatencyMs = Int((session.outputLatency + session.inputLatency) * 1000)
    }

    private func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func applyEq(hp: Int, mid: Int, lp: Int) {
        let b0 = eq.bands[0]
        b0.filterType = .highPass; b0.frequency = Float(hp); b0.bypass = false
        let b1 = eq.bands[1]
        b1.filterType = .parametric; b1.frequency = Float(mid); b1.bandwidth = 1.0
        b1.gain = 3.0 * strength; b1.bypass = false
        let b2 = eq.bands[2]
        b2.filterType = .lowPass; b2.frequency = Float(lp); b2.bypass = false
    }

    private func emitMetrics(buffer: AVAudioPCMBuffer) {
        guard let ch = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<n { sum += ch[i] * ch[i] }
        let rms = sqrtf(sum / Float(max(n, 1)))
        let db = rms > 0 ? 20 * log10f(rms) : -90
        DispatchQueue.main.async {
            self.eventSink?(["latencyMs": self.lastLatencyMs, "noiseDb": Double(db)])
        }
    }
}
