package com.quietly.app

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.EventChannel

class BtReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val connected = intent.action == BluetoothDevice.ACTION_ACL_CONNECTED
        sink?.success(connected)
    }
    companion object { @JvmStatic var sink: EventChannel.EventSink? = null }
}
