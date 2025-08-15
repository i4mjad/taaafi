package com.amjadkhalfan.reboot_app_3
import android.content.*

class PickupStore(private val ctx: Context) {
  fun inc() { val p = ctx.getSharedPreferences("pickups", Context.MODE_PRIVATE); p.edit().putInt("count", p.getInt("count",0)+1).apply() }
  fun count(): Int { return ctx.getSharedPreferences("pickups", Context.MODE_PRIVATE).getInt("count",0) }
}
class ScreenReceiver: BroadcastReceiver(){ override fun onReceive(c: Context, i: Intent){ if (i.action==Intent.ACTION_USER_PRESENT) PickupStore(c).inc() } }
class BootReceiver: BroadcastReceiver(){ override fun onReceive(c: Context, i: Intent){ /* (Optional) reschedule workers */ } }
