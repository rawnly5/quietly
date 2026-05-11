package com.quietly.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val audioChannel = "com.quietly.app/audio"
    private val audioEvents = "com.quietly.app/audio.events"
    private val btEvents = "com.quietly.app/bt"

    private lateinit var engine: AncEngine
    private var metricsSink: EventChannel.EventSink? = null
    private var btSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = AncEngine(applicationContext) { latencyMs, noiseDb ->
            runOnUiThread {
                metricsSink?.success(mapOf("latencyMs" to latencyMs, "noiseDb" to noiseDb))
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            val args = call.arguments as Map<*, *>
                            val sampleRate = (args["sampleRate"] as Number).toInt()
                            val fftSize = (args["fftSize"] as Number).toInt()
                            val strength = (args["strength"] as Number).toDouble()
                            val svcIntent = Intent(this, AncForegroundService::class.java)
                            startForegroundService(svcIntent)
                            engine.start(sampleRate, fftSize, strength.toFloat())
                            result.success(null)
                        }
                        "stop" -> {
                            engine.stop()
                            stopService(Intent(this, AncForegroundService::class.java))
                            result.success(null)
                        }
                        "applyMode" -> {
                            val args = call.arguments as Map<*, *>
                            engine.applyMode(
                                (args["sampleRate"] as Number).toInt(),
                                (args["fftSize"] as Number).toInt(),
                                (args["strength"] as Number).toDouble().toFloat()
                            )
                            result.success(null)
                        }
                        "latency" -> result.success(engine.measuredLatencyMs())
                        "setEq" -> {
                            val args = call.arguments as Map<*, *>
                            engine.setEq(
                                (args["hp"] as Number).toInt(),
                                (args["mid"] as Number).toInt(),
                                (args["lp"] as Number).toInt()
                            )
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Throwable) {
                    result.error("ENGINE", e.message, null)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, audioEvents)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) { metricsSink = sink }
                override fun onCancel(args: Any?) { metricsSink = null }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, btEvents)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    btSink = sink
                    BtReceiver.sink = sink
                }
                override fun onCancel(args: Any?) {
                    btSink = null
                    BtReceiver.sink = null
                }
            })
    }
}
