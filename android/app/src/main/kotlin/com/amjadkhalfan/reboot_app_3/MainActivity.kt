package com.amjadkhalfan.reboot_app_3      
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings

class MainActivity: FlutterActivity() {
  private val CHANNEL = "analytics.usage"
  object FocusIntents {
    fun openUsageAccessSettings(activity: FlutterActivity) {
      val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      activity.startActivity(intent)
    }
  }
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val bridge = UsageBridge(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      FocusLog.d("Dart→Android ${call.method}", call.arguments)
      try {
        when(call.method){
          "android_checkUsageAccess" -> {
            val hasAccess = bridge.hasUsageAccess()
            FocusLog.d("Android→Dart ${call.method} OK", hasAccess)
            result.success(hasAccess)
          }
          "android_getSnapshot" -> {
            val snapshot = bridge.todaySnapshot().toString()
            FocusLog.d("Android→Dart ${call.method} OK", snapshot)
            result.success(snapshot)
          }
          "android_getLogs" -> {
            val logs = FocusLog.readLogs()
            FocusLog.d("Android→Dart ${call.method} count=${logs.size}")
            result.success(logs)
          }
          "android_clearLogs" -> {
            FocusLog.clearLogs()
            FocusLog.d("Android→Dart ${call.method} done")
            result.success(true)
          }
          "android_requestUsageAccess" -> {
            // Open Settings screen for Usage Access
            FocusIntents.openUsageAccessSettings(this)
            result.success(true)
          }
          else -> {
            FocusLog.d("Android→Dart ${call.method} NOT_IMPLEMENTED")
            result.notImplemented()
          }
        }
      } catch (t: Throwable) {
        FocusLog.e("Android handler error ${call.method}", t)
        result.error("bridge_error", t.message, null)
      }
    }
  }
}
