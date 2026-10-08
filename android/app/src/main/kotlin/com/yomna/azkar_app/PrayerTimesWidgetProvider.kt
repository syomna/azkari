package com.yomna.azkar_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val MINUTES_PER_DAY = 24 * 60

        /// Never wait longer than this between repaints: the countdown animates
        /// itself, so this only has to cover stale times and data rollovers.
        const val REFRESH_MAX_MINUTES = 15

        /// Used when the next prayer's time cannot be parsed at all.
        const val REFRESH_FALLBACK_MINUTES = 15

        val COLOR_ACCENT = 0xFF146B3C.toInt()
        val COLOR_WHITE = 0xFFFFFFFF.toInt()
    }

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
    private val prayerIconIds = listOf(
        R.id.prayer_1_icon, R.id.prayer_2_icon, R.id.prayer_3_icon,
        R.id.prayer_4_icon, R.id.prayer_5_icon, R.id.prayer_6_icon
    )
    private val prayerContainerIds = listOf(
        R.id.prayer_1, R.id.prayer_2, R.id.prayer_3,
        R.id.prayer_4, R.id.prayer_5, R.id.prayer_6
    )

    /// One icon per prayer, matching the reference design: sparkles for Fajr,
    /// sun on the horizon for Sunrise, sun for Duhr and Asr, sunset for
    /// Maghrib, crescent and star for Isha.
    private val prayerIconRes = listOf(
        R.drawable.ic_prayer_fajr,
        R.drawable.ic_prayer_sunrise,
        R.drawable.ic_prayer_sun,
        R.drawable.ic_prayer_sun,
        R.drawable.ic_prayer_sunset,
        R.drawable.ic_prayer_isha
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
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
        val dayEntry = todayEntry(prefs, displayZone(prefs))
        val nowMinutes = currentMinutesSinceMidnight(displayZone(prefs))
        val names = prayerKeys.map { key ->
            prefs.getString("prayer_name_$key", "") ?: ""
        }
        val rawTimes = prayerKeys.map { key ->
            dayEntry?.get(key) ?: (prefs.getString("prayer_$key", "") ?: "")
        }

        // The prayer whose countdown runs is the one with the SMALLEST positive
        // minutes-from-now. Skimming the canonical order for the first future
        // time only works while the times stay chronologically sorted; a manual
        // override (e.g. maghrib moved earlier than asr) reorders the day, so
        // the first future entry is not necessarily the soonest adhan.
        var nextPrayerIndex = -1
        var bestDiff = Int.MAX_VALUE
        for (i in rawTimes.indices) {
            if (rawTimes[i].isEmpty()) continue
            val prayerMinutes = parseTimeToMinutes(rawTimes[i]) ?: continue
            var diff = prayerMinutes - nowMinutes
            if (diff <= 0) diff += MINUTES_PER_DAY
            if (diff < bestDiff) {
                bestDiff = diff
                nextPrayerIndex = i
            }
        }

        // When nothing could be parsed at all, index 0 is a safe fallback: it
        // means tomorrow's first prayer, and `remainingMinutes` wraps it across
        // midnight for us.
        if (nextPrayerIndex == -1) nextPrayerIndex = 0

        // Display order mirrors the iOS widget: the prayer the countdown refers
        // to leads in the wide card, and the other five follow in canonical
        // order. Keeping the raw index here would put the countdown inside a
        // card for a different prayer as soon as it was not the first of the
        // day, and would mint-highlight a slot the countdown is not attached to.
        val remaining = remainingMinutes(rawTimes[nextPrayerIndex], nowMinutes)

        // Keep original positions - no reordering
        for (slot in prayerKeys.indices) {
            val i = slot
            views.setImageViewResource(prayerIconIds[slot], prayerIconRes[i])
            views.setTextViewText(prayerNameIds[slot], names[i])
            views.setTextViewText(
                prayerTimeIds[slot],
                toArabicDigits(rawTimes[i].ifEmpty { "--:--" })
            )
        }

        // Only highlight the next prayer in its original position
        for (slot in prayerKeys.indices) {
            val active = slot == nextPrayerIndex
            views.setInt(
                prayerContainerIds[slot],
                "setBackgroundResource",
                if (active) R.drawable.widget_cell_active else R.drawable.widget_cell
            )
            val textColor = if (active) COLOR_ACCENT else COLOR_WHITE
            views.setTextColor(prayerNameIds[slot], textColor)
            views.setTextColor(prayerTimeIds[slot], textColor)
            views.setInt(prayerIconIds[slot], "setColorFilter", textColor)
        }

        // Header dates come from the same day entry as the times above, falling
        // back to the standalone keys the app writes alongside it. The widget
        // can't compute a hijri date itself, so an empty value has to stay
        // blank rather than fall back to something misleading.
        // The app formats these with Latin digits, so they get the same
        // Eastern Arabic conversion the prayer times do.
        views.setTextViewText(
            R.id.widget_hijri_date,
            toArabicDigits(
                dayEntry?.get("hijri") ?: (prefs.getString("hijri_date", "") ?: "")
            )
        )
        views.setTextViewText(
            R.id.widget_gregorian_date,
            toArabicDigits(
                dayEntry?.get("gregorian") ?: (prefs.getString("gregorian_date", "") ?: "")
            )
        )

        // The wide card already shows this prayer's name, so the label is only a
        // short lead-in. Naming it keeps the two platforms worded identically.
        views.setTextViewText(
            R.id.widget_countdown_label,
            "باقي حتى ${names[nextPrayerIndex]}"
        )
        setCountdown(views, remaining)
        // No per-minute refresh: the Chronometer animates itself in place. This
        // alarm only keeps the stored times and data from going stale.
        PrayerTimesUpdateReceiver.scheduleUpdateIn(
            context,
            (remaining ?: REFRESH_FALLBACK_MINUTES).coerceIn(1, REFRESH_MAX_MINUTES).toLong()
        )

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

    /// Drives the countdown from a [android.widget.Chronometer] instead of
    /// repainting the widget every minute.
    ///
    /// The AppWidget framework animates a Chronometer in place on its own, so
    /// the value ticks down live with no broadcasts, no alarms and no battery
    /// cost. Refreshing per-minute via `AlarmManager` cannot do this: exact
    /// alarms are denied by default on Android 12+, so the fallback is inexact
    /// and gets batched, and 1440 daily wakeups would be unacceptable anyway.
    ///
    /// All three of these calls are required, and each is easy to miss:
    ///  - `started = true`, because Chronometer only schedules its 1s tick while
    ///    started (`updateRunning` also needs the view visible, which it is).
    ///  - `setChronometerCountDown(true)`, otherwise it counts *up* from the base.
    ///  - `"%s"` as the format, which passes the built-in `H:MM:SS` text through
    ///    untouched. Chronometer applies the format with
    ///    `Formatter.format(format, text)`, so real strftime patterns like
    ///    `%H:%M` would throw and silently fall back.
    ///
    /// `formatElapsedTime` formats with `Locale.getDefault()`, so the digits
    /// follow the device locale.
    private fun setCountdown(views: RemoteViews, remainingMinutes: Int?) {
        if (remainingMinutes == null) {
            views.setViewVisibility(R.id.widget_countdown_time, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_countdown_time, View.VISIBLE)
        views.setChronometerCountDown(R.id.widget_countdown_time, true)
        // `setChronometer` expects a base on the elapsed-realtime timebase,
        // in the future so the countdown runs towards it.
        views.setChronometer(
            R.id.widget_countdown_time,
            SystemClock.elapsedRealtime() + remainingMinutes * 60_000L,
            "%s",
            true
        )
    }

    /// The IANA timezone the app computed the prayer times in (its display
    /// timezone): the picked city's zone, or the device's own zone on auto.
    /// The AppWidgetProvider runs on the same device as the app, so it can
    /// always read the device clock — but that clock means nothing when the
    /// times belong to a city in another timezone, which would shift the
    /// next-prayer decision and countdown by the whole offset. Returns `null`
    /// when absent or unknown, so callers fall back to the device zone.
    private fun displayZone(prefs: android.content.SharedPreferences): TimeZone? {
        val name = prefs.getString("widget_timezone", "") ?: ""
        if (name.isEmpty()) return null
        val zone = TimeZone.getTimeZone(name)
        return if (zone.id == name) zone else null
    }

    /// Reads today's entry from the app-written rolling snapshot, returning
    /// `null` when the snapshot is missing or has no entry for today.
    ///
    /// The entry carries the prayer times alongside the hijri/gregorian date
    /// labels, so the header and the grid are always describing the same day.
    /// "Today" is the display timezone's day ([zone]), not the device's.
    private fun todayEntry(
        prefs: android.content.SharedPreferences,
        zone: TimeZone?
    ): Map<String, String>? {
        val json = prefs.getString("widget_times_json", "") ?: ""
        if (json.isEmpty()) return null
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        if (zone != null) dateFormat.timeZone = zone
        val todayKey = dateFormat.format(Date())
        return try {
            val blob = JSONObject(json)
            if (!blob.has(todayKey)) return null
            val day = blob.getJSONObject(todayKey)
            val keys = day.keys()
            buildMap {
                while (keys.hasNext()) {
                    val key = keys.next()
                    put(key, day.optString(key, ""))
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun currentMinutesSinceMidnight(zone: TimeZone?): Int {
        val cal = if (zone != null) Calendar.getInstance(zone) else Calendar.getInstance()
        return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
    }

    /// Minutes left until [time], or `null` when it cannot be parsed. Times that
    /// have already passed today are treated as tomorrow's, so the countdown
    /// stays positive across the midnight boundary.
    private fun remainingMinutes(time: String?, nowMinutes: Int): Int? {
        val target = parseTimeToMinutes(time ?: "") ?: return null
        val diff = target - nowMinutes
        return if (diff > 0) diff else diff + MINUTES_PER_DAY
    }

    /// Converts digits to Eastern Arabic numerals for display only.
    private fun toArabicDigits(value: String): String {
        val digits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
        return value.map { if (it in '0'..'9') digits[it - '0'] else it }
            .joinToString("")
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
