package com.amjadkhalfan.reboot_app_3.fort

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import com.amjadkhalfan.reboot_app_3.FocusLog
import com.amjadkhalfan.reboot_app_3.PickupStore
import com.amjadkhalfan.reboot_app_3.UsageBridge
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

/**
 * MethodChannel handler for the Fort feature.
 * Provides category-level usage aggregation on top of the existing UsageBridge.
 */
class FortMethodChannel(
    private val context: Context,
    private val usageBridge: UsageBridge
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.taaafi.fort"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        FocusLog.d("Fort Dart→Android ${call.method}", call.arguments)
        try {
            when (call.method) {
                "android_getCategoryUsage" -> {
                    val usage = getCategoryUsage()
                    FocusLog.d("Fort Android→Dart ${call.method} OK", usage)
                    result.success(usage.toString())
                }
                "android_checkUsageAccess" -> {
                    val hasAccess = usageBridge.hasUsageAccess()
                    FocusLog.d("Fort Android→Dart ${call.method} OK", hasAccess)
                    result.success(hasAccess)
                }
                "android_requestUsageAccess" -> {
                    FocusLog.d("Fort: opening usage access settings")
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                }
                else -> {
                    FocusLog.d("Fort Android→Dart ${call.method} NOT_IMPLEMENTED")
                    result.notImplemented()
                }
            }
        } catch (t: Throwable) {
            FocusLog.e("Fort handler error ${call.method}", t)
            result.error("fort_bridge_error", t.message, null)
        }
    }

    /**
     * Aggregates today's usage stats by category using CategoryMapper.
     * Returns JSON: { categories: [{type, minutes}], totalScreenTimeMinutes, pickups, date }
     */
    private fun getCategoryUsage(): JSONObject {
        val t0 = System.currentTimeMillis()
        FocusLog.d("getCategoryUsage:start")

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            cal.timeInMillis,
            System.currentTimeMillis()
        )

        // Aggregate by category
        val categoryMinutes = mutableMapOf<CategoryMapper.Category, Long>()
        stats.filter { it.totalTimeInForeground > 0 }.forEach { stat ->
            val category = CategoryMapper.categorize(stat.packageName)
            val minutes = stat.totalTimeInForeground / 60000
            categoryMinutes[category] = (categoryMinutes[category] ?: 0) + minutes
        }

        val categories = JSONArray()
        var totalMinutes = 0L
        categoryMinutes.entries
            .sortedByDescending { it.value }
            .forEach { (category, minutes) ->
                categories.put(
                    JSONObject()
                        .put("type", category.key)
                        .put("minutes", minutes)
                )
                totalMinutes += minutes
            }

        val pickups = PickupStore(context).count()

        val result = JSONObject()
            .put("categories", categories)
            .put("totalScreenTimeMinutes", totalMinutes)
            .put("pickups", pickups)
            .put("date", cal.timeInMillis / 1000)

        FocusLog.d("getCategoryUsage:done ${System.currentTimeMillis() - t0}ms",
            "categories=${categories.length()} total=${totalMinutes}m pickups=$pickups")

        return result
    }
}
