package com.amjadkhalfan.reboot_app_3
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Binder
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class UsageBridge(private val ctx: Context) {
  fun hasUsageAccess(): Boolean {
    FocusLog.d("hasUsageAccess:start")
    val aom = ctx.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
    val mode = if (Build.VERSION.SDK_INT >= 29)
      aom.unsafeCheckOpNoThrow("android:get_usage_stats", Binder.getCallingUid(), ctx.packageName)
    else aom.checkOpNoThrow("android:get_usage_stats", Binder.getCallingUid(), ctx.packageName)
    val hasAccess = mode == AppOpsManager.MODE_ALLOWED
    FocusLog.d("hasUsageAccess:done $hasAccess")
    return hasAccess
  }
  
  fun todaySnapshot(): JSONObject {
    val t0 = System.currentTimeMillis()
    FocusLog.d("todaySnapshot:start")
    
    val usm = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val cal = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY,0); set(Calendar.MINUTE,0); set(Calendar.SECOND,0); set(Calendar.MILLISECOND,0) }
    val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, cal.timeInMillis, System.currentTimeMillis())
    
    val apps = JSONArray()
    stats.filter { it.totalTimeInForeground > 0 }.forEach {
      apps.put(JSONObject().put("pkg", it.packageName).put("label", it.packageName).put("minutes", it.totalTimeInForeground/60000))
    }
    
    val pickups = PickupStore(ctx).count()
    val result = JSONObject().put("apps", apps).put("domains", JSONArray()).put("pickups", pickups).put("notifications", JSONObject.NULL).put("generatedAt", System.currentTimeMillis()/1000)
    
    FocusLog.d("todaySnapshot:done ${System.currentTimeMillis()-t0}ms", "apps=${apps.length()} pickups=$pickups")
    return result
  }
}
