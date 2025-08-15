package com.amjadkhalfan.reboot_app_3      
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "analytics.usage"
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val bridge = UsageBridge(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when(call.method){
        "android_checkUsageAccess" -> result.success(bridge.hasUsageAccess())
        "android_getSnapshot" -> result.success(bridge.todaySnapshot().toString())
        else -> result.notImplemented()
      }
    }
  }
}
