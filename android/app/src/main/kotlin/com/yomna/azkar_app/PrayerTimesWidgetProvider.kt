package com.yomna.azkar_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        PrayerTimesUpdateReceiver.scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        PrayerTimesUpdateReceiver.cancelUpdate(context)
    }

    private val prayerKeys = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
    private val prayerNameIds = listOf(
        R.id.prayer_1_name, R.id.prayer_2_name, R.id.prayer_3_name,
        R.id.prayer_4_name, R.id.prayer_5_name, R.id.prayer_6_name
    )
    private val prayerTimeIds = listOf(
        R.id.prayer_1_time, R.id.prayer_2_time, R.id.prayer_3_time,
        R.id.prayer_4_time, R.id.prayer_5_time, R.id.prayer_6_time
    )
    private val prayerContainerIds = listOf(
        R.id.prayer_1, R.id.prayer_2, R.id.prayer_3,
        R.id.prayer_4, R.id.prayer_5, R.id.prayer_6
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        PrayerTimesUpdateReceiver.scheduleNextUpdate(context)
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

        // The app writes a rolling multi-day snapshot (`widget_times_json`).
        // Prefer today's entry so the widget stays correct even if the app
        // hasn't run for days; fall back to the single saved day otherwise.
        val today = todayEntry(prefs)
        val dayTimes = today?.times
        val hijriDate = today?.hijriDate ?: (prefs.getString("hijri_date", "") ?: "")
        val gregorianDate = today?.gregorianDate ?: (prefs.getString("gregorian_date", "") ?: "")
        views.setTextViewText(R.id.widget_hijri_date, hijriDate)
        views.setTextViewText(R.id.widget_gregorian_date, gregorianDate)

        val nowMinutes = currentMinutesSinceMidnight()
        var nextPrayerIndex = -1

        for (i in prayerKeys.indices) {
            val key = prayerKeys[i]
            val name = prefs.getString("prayer_name_$key", "") ?: ""
            val time = dayTimes?.get(key) ?: (prefs.getString("prayer_$key", "") ?: "")

            views.setTextViewText(prayerNameIds[i], name)
            views.setTextViewText(prayerTimeIds[i], time.ifEmpty { "--:--" })

            if (nextPrayerIndex == -1 && time.isNotEmpty()) {
                val prayerMinutes = parseTimeToMinutes(time)
                if (prayerMinutes != null && prayerMinutes > nowMinutes) {
                    nextPrayerIndex = i
                }
            }
        }

        if (nextPrayerIndex == -1) nextPrayerIndex = 0

        for (i in prayerKeys.indices) {
            if (i == nextPrayerIndex) {
                views.setInt(prayerContainerIds[i], "setBackgroundResource", R.drawable.prayer_cell_active_bg)
                views.setTextColor(prayerTimeIds[i], 0xFFFFFFFF.toInt())
                views.setTextColor(prayerNameIds[i], 0xFFFFFFFF.toInt())
            } else {
                views.setInt(prayerContainerIds[i], "setBackgroundResource", R.drawable.prayer_cell_bg)
                views.setTextColor(prayerTimeIds[i], 0xD922A351.toInt())
                views.setTextColor(prayerNameIds[i], 0x99FFFFFF.toInt())
            }
        }

        val nextPrayerName = prefs.getString("prayer_name_${prayerKeys[nextPrayerIndex]}", "") ?: ""
        views.setTextViewText(R.id.widget_next_label, "التالي: $nextPrayerName")

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (intent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private data class DayEntry(
        val times: Map<String, String>,
        val hijriDate: String,
        val gregorianDate: String
    )

    /// Reads today's times + date labels from the app-written rolling snapshot,
    /// returning `null` when the snapshot is missing or has no entry for today.
    private fun todayEntry(prefs: android.content.SharedPreferences): DayEntry? {
        val json = prefs.getString("widget_times_json", "") ?: ""
        if (json.isEmpty()) return null
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        return try {
            val blob = JSONObject(json)
            if (!blob.has(todayKey)) return null
            val day = blob.getJSONObject(todayKey)
            val times = prayerKeys.associateWith { day.optString(it, "") }
            DayEntry(
                times = times,
                hijriDate = day.optString("hijri", ""),
                gregorianDate = day.optString("gregorian", "")
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun currentMinutesSinceMidnight(): Int {
        val cal = Calendar.getInstance()
        return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
    }

    private fun parseTimeToMinutes(time: String): Int? {
        val cleaned = time.trim()
        if (cleaned.isEmpty()) return null

        val isPM = cleaned.contains("م")
        val timePart = cleaned.replace(Regex("[صم\\s]"), "").trim()
        val parts = timePart.split(":")
        if (parts.size < 2) return null

        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null

        var h24 = hour
        if (isPM && hour != 12) h24 += 12
        if (!isPM && hour == 12) h24 = 0

        return h24 * 60 + minute
    }
}
