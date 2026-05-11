package com.quietly.app.dsp

import kotlin.math.abs
import kotlin.math.sqrt

class Vad {
    private var idleFrames = 0

    fun isVoice(buf: ShortArray, n: Int): Boolean {
        var sumSq = 0.0
        var zc = 0
        var prev: Short = 0
        for (i in 0 until n) {
            sumSq += buf[i] * buf[i].toDouble()
            if ((buf[i] >= 0) != (prev >= 0)) zc++
            prev = buf[i]
        }
        val rms = sqrt(sumSq / n)
        val zcr = zc.toDouble() / n
        val voiced = rms > 350 && zcr in 0.02..0.30
        idleFrames = if (voiced) 0 else idleFrames + 1
        return voiced
    }
}
