package com.quietly.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.util.Log
import com.quietly.app.dsp.BiquadFilter
import com.quietly.app.dsp.SpectralSubtractor
import com.quietly.app.dsp.Vad
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.sqrt

class AncEngine(
    private val ctx: Context,
    private val onMetrics: (latencyMs: Int, noiseDb: Double) -> Unit
) {
    private var thread: Thread? = null
    @Volatile private var running = false
    @Volatile private var strength = 1.0f
    @Volatile private var sampleRate = 48000
    @Volatile private var fftSize = 1024
    @Volatile private var hpHz = 80
    @Volatile private var midHz = 1000
    @Volatile private var lpHz = 14000
    private var lastLatencyMs = 0

    fun measuredLatencyMs() = lastLatencyMs

    fun start(sr: Int, fft: Int, strength: Float) {
        if (running) return
        this.sampleRate = sr
        this.fftSize = fft
        this.strength = strength
        running = true
        thread = Thread(::loop, "QuietlyAudio").apply {
            priority = Thread.MAX_PRIORITY
            start()
        }
    }

    fun applyMode(sr: Int, fft: Int, strength: Float) {
        this.sampleRate = sr; this.fftSize = fft; this.strength = strength
    }

    fun setEq(hp: Int, mid: Int, lp: Int) { hpHz = hp; midHz = mid; lpHz = lp }

    fun stop() {
        running = false
        thread?.join(500)
        thread = null
    }

    private fun loop() {
        val sr = sampleRate
        val bufFrames = max(fftSize, AudioRecord.getMinBufferSize(sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT))
        val outBuf = AudioTrack.getMinBufferSize(sr, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)

        val record = try {
            AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, sr, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufFrames * 2)
        } catch (e: SecurityException) { Log.e("Quietly", "mic denied", e); return }

        if (NoiseSuppressor.isAvailable()) NoiseSuppressor.create(record.audioSessionId)?.enabled = true
        if (AcousticEchoCanceler.isAvailable()) AcousticEchoCanceler.create(record.audioSessionId)?.enabled = true
        if (AutomaticGainControl.isAvailable()) AutomaticGainControl.create(record.audioSessionId)?.enabled = true

        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build())
            .setAudioFormat(AudioFormat.Builder()
                .setSampleRate(sr).setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setBufferSizeInBytes(outBuf * 2)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build()

        record.startRecording(); track.play()

        val frame = ShortArray(fftSize)
        val ss = SpectralSubtractor(fftSize)
        val vad = Vad()
        val hp = BiquadFilter.highPass(sr.toDouble(), hpHz.toDouble())
        val lp = BiquadFilter.lowPass(sr.toDouble(), lpHz.toDouble())
        val perFrameMs = (fftSize * 1000.0 / sr).toInt()

        var counter = 0
        val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am.mode = AudioManager.MODE_NORMAL

        while (running) {
            val n = record.read(frame, 0, fftSize)
            if (n <= 0) continue

            var sumSq = 0.0
            for (i in 0 until n) sumSq += frame[i] * frame[i].toDouble()
            val rms = sqrt(sumSq / n)
            val db = if (rms > 0) 20.0 * log10(rms / 32768.0) else -90.0

            val voice = vad.isVoice(frame, n)
            ss.process(frame, n, learnNoise = !voice, strength = strength)

            for (i in 0 until n) {
                var v = frame[i].toDouble() / 32768.0
                v = hp.process(v)
                v = lp.process(v)
                frame[i] = (v.coerceIn(-1.0, 1.0) * 32767).toInt().toShort()
            }

            track.write(frame, 0, n)

            if (++counter % 8 == 0) {
                lastLatencyMs = perFrameMs * 2
                onMetrics(lastLatencyMs, db)
            }
        }

        try { record.stop(); record.release() } catch (_: Throwable) {}
        try { track.stop(); track.release() } catch (_: Throwable) {}
    }
}
