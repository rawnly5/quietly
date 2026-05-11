package com.quietly.app.dsp

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

class BiquadFilter private constructor(
    private val b0: Double, private val b1: Double, private val b2: Double,
    private val a1: Double, private val a2: Double,
) {
    private var z1 = 0.0
    private var z2 = 0.0

    fun process(x: Double): Double {
        val y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }

    companion object {
        fun highPass(sr: Double, fc: Double, q: Double = 0.707): BiquadFilter {
            val w = 2 * PI * fc / sr
            val alpha = sin(w) / (2 * q)
            val cosw = cos(w)
            val a0 = 1 + alpha
            val b0 = (1 + cosw) / 2 / a0
            val b1 = -(1 + cosw) / a0
            val b2 = (1 + cosw) / 2 / a0
            val a1 = -2 * cosw / a0
            val a2 = (1 - alpha) / a0
            return BiquadFilter(b0, b1, b2, a1, a2)
        }

        fun lowPass(sr: Double, fc: Double, q: Double = 0.707): BiquadFilter {
            val w = 2 * PI * fc / sr
            val alpha = sin(w) / (2 * q)
            val cosw = cos(w)
            val a0 = 1 + alpha
            val b0 = (1 - cosw) / 2 / a0
            val b1 = (1 - cosw) / a0
            val b2 = (1 - cosw) / 2 / a0
            val a1 = -2 * cosw / a0
            val a2 = (1 - alpha) / a0
            return BiquadFilter(b0, b1, b2, a1, a2)
        }
    }
}
