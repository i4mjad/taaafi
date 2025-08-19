package com.amjadkhalfan.reboot_app_3

import android.util.Log

object FocusLog {
    private const val TAG = "Focus"
    private val buffer: MutableList<String> = mutableListOf()
    private const val MAX = 200
    
    @JvmStatic 
    fun d(msg: String) { 
        if (BuildConfig.DEBUG) Log.d(TAG, msg)
        synchronized(buffer) {
            buffer.add("D [Android] $msg")
            if (buffer.size > MAX) buffer.removeAt(0)
        }
    }
    
    @JvmStatic 
    fun e(msg: String, t: Throwable? = null) { 
        Log.e(TAG, msg, t)
        synchronized(buffer) {
            buffer.add("E [Android] $msg")
            if (buffer.size > MAX) buffer.removeAt(0)
        }
    }
    
    @JvmStatic 
    fun d(msg: String, data: Any?) {
        if (!BuildConfig.DEBUG) return
        val s = data?.toString() ?: ""
        val truncated = if (s.length <= 300) "$msg — $s" else "$msg — ${s.substring(0, 300)}…"
        Log.d(TAG, truncated)
        synchronized(buffer) {
            buffer.add("D [Android] $truncated")
            if (buffer.size > MAX) buffer.removeAt(0)
        }
    }

    @JvmStatic
    fun readLogs(): List<String> {
        synchronized(buffer) { return buffer.toList() }
    }

    @JvmStatic
    fun clearLogs() {
        synchronized(buffer) { buffer.clear() }
    }
}
