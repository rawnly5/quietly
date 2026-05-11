package com.quietly.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Intentionally a no-op: we never auto-start the engine without
        // explicit user action (privacy + battery respect).
    }
}
