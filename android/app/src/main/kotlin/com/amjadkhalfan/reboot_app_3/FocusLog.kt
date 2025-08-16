package com.amjadkhalfan.reboot_app_3

import android.util.Log

object FocusLog {
    private const val TAG = "Focus"
    
    @JvmStatic 
    fun d(msg: String) { 
        if (BuildConfig.DEBUG) Log.d(TAG, msg) 
    }
    
    @JvmStatic 
    fun e(msg: String, t: Throwable? = null) { 
        Log.e(TAG, msg, t) 
    }
    
    @JvmStatic 
    fun d(msg: String, data: Any?) {
        if (!BuildConfig.DEBUG) return
        val s = data?.toString() ?: ""
        val truncated = if (s.length <= 300) "$msg — $s" else "$msg — ${s.substring(0, 300)}…"
        Log.d(TAG, truncated)
    }
}
