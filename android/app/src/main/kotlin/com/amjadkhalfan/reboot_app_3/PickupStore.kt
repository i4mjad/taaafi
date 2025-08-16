package com.amjadkhalfan.reboot_app_3
import android.content.*

class PickupStore(private val ctx: Context) {
  fun inc() { 
    FocusLog.d("PickupStore.inc()")
    val p = ctx.getSharedPreferences("pickups", Context.MODE_PRIVATE)
    val oldCount = p.getInt("count", 0)
    val newCount = oldCount + 1
    p.edit().putInt("count", newCount).apply()
    FocusLog.d("PickupStore.inc() $oldCount -> $newCount")
  }
  
  fun count(): Int { 
    val count = ctx.getSharedPreferences("pickups", Context.MODE_PRIVATE).getInt("count", 0)
    FocusLog.d("PickupStore.count() = $count")
    return count
  }
}

class ScreenReceiver: BroadcastReceiver() { 
  override fun onReceive(c: Context, i: Intent) { 
    if (i.action == Intent.ACTION_USER_PRESENT) {
      FocusLog.d("ScreenReceiver.onReceive USER_PRESENT")
      PickupStore(c).inc()
    }
  } 
}

class BootReceiver: BroadcastReceiver() { 
  override fun onReceive(c: Context, i: Intent) { 
    FocusLog.d("BootReceiver.onReceive ${i.action}")
    /* (Optional) reschedule workers */ 
  } 
}
