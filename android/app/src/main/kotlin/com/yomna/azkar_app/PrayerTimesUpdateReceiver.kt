package com.yomna.azkar_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

class PrayerTimesUpdateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidgetProvider::class.java))
        if (ids.isNotEmpty()) {
            val updateIntent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(updateIntent)
            // No fixed refresh here: the provider schedules its own next update
            // from the countdown it just rendered, so overwriting it with the
            // periodic interval would desync the "minutes left" label.
        }
    }

    companion object {
        private const val REQUEST_CODE = 7777
        const val INTERVAL_MS = 900_000L

        fun scheduleNextUpdate(context: Context) =
            scheduleUpdateIn(context, INTERVAL_MS / 60_000L)

        /**
         * Schedules the next repaint [delayMinutes] from now.
         *
         * Used for both the periodic retry and the countdown's own refresh, so a
         * single PendingIntent is reused and each call replaces the last one
         * instead of stacking alarms.
         */
        fun scheduleUpdateIn(context: Context, delayMinutes: Long) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerTimesUpdateReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val delayMs = delayMinutes.coerceAtLeast(1) * 60_000L
            setInexact(alarmManager, pendingIntent, delayMs)
        }

        private fun setInexact(
            alarmManager: AlarmManager,
            pendingIntent: PendingIntent,
            delayMs: Long
        ) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + delayMs,
                pendingIntent
            )
        }

        fun cancelUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerTimesUpdateReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}
