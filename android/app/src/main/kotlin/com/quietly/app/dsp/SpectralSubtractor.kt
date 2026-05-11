package com.quietly.app.dsp

import kotlin.math.max
import kotlin.math.sqrt

/**
 * Lightweight time-domain "spectral subtraction" approximation:
 * maintains an exponential noise-floor estimate and attenuates
 * frames whose energy is close to the floor. Avoids a full FFT
 * to stay within the < 10% battery/hour budget on mid-range CPUs.
 */
class SpectralSubtractor(private val frameSize: Int) {
    private var noiseFloor = 0.0
    private val alpha = 0.92

    fun process(buf: ShortArray, n: Int, learnNoise: Boolean, strength: Float) {
        var sumSq = 0.0
        for (i in 0 until n) sumSq += buf[i] * buf[i].toDouble()
        val rms = sqrt(sumSq / n)

        if (learnNoise) {
            noiseFloor = if (noiseFloor == 0.0) rms else alpha * noiseFloor + (1 - alpha) * rms
        }

        if (noiseFloor <= 0 || strength <= 0f) return
        val snr = rms / max(noiseFloor, 1.0)
        // Wiener-like gain: low SNR -> heavy attenuation, high SNR -> pass-through.
        val gain = (1.0 - strength.toDouble() / max(snr, 1e-3)).coerceIn(0.05, 1.0)
        for (i in 0 until n) buf[i] = (buf[i] * gain).toInt().toShort()
    }
}
