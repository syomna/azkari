import WidgetKit
import SwiftUI

struct PrayerTimesEntry: TimelineEntry {
    /// One prayer slot. A named struct rather than a tuple so the view can
    /// carry the prayer key through to its icon lookup.
    struct Prayer {
        let key: String
        let name: String
        let time: String
        let isActive: Bool
    }

    let date: Date
    /// Hijri and gregorian labels for [date], pre-formatted by the app because
    /// neither platform can derive a hijri date on its own.
    ///
    /// Read from the same snapshot day entry as [prayerTimes], so the header
    /// and the grid always describe the same day.
    let hijriText: String
    let gregorianText: String
    let prayerTimes: [Prayer]
    let nextPrayerName: String
    /// Remaining time until the next adhan, pre-formatted for display.
    ///
    /// Used for placeholders, previews and entries without any usable prayer
    /// time; the footer countdown is computed from [countdownTargets] whenever
    /// one exists.
    let countdownText: String
    /// Minutes left until the next prayer, or `nil` when undeterminable. Used
    /// only to schedule the next timeline refresh.
    let remainingMinutes: Int?
    /// Absolute instants of each prayer's next occurrence (keyed by prayer key).
    /// Populated for every day so even a pre-built future-day entry keeps a
    /// live seconds countdown from the first render after midnight.
    let countdownTargets: [String: Date]
}

struct PrayerTimesProvider: TimelineProvider {
    static let suiteName = "group.com.yomna.azkarApp"
    static let timesJsonKey = "widget_times_json"

    /// Upper bound on how long the countdown may go unrefreshed. Matches the
    /// Android widget's refresh cap; WidgetKit will usually be lazier than this.
    private static let maxRefreshMinutes = 15

    private static let prayerKeys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]

    private static let arabicNames = [
        "fajr": "الفجر", "sunrise": "الشروق", "dhuhr": "الظهر",
        "asr": "العصر", "maghrib": "المغرب", "isha": "العشاء"
    ]

    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            hijriText: "5 ربيع الآخر 1447 هـ",
            gregorianText: "الثلاثاء 5 يناير 2026",
            prayerTimes: Self.placeholderPrayers,
            nextPrayerName: "الفجر",
            countdownText: "3:35",
            remainingMinutes: 215,
            countdownTargets: [:]
        )
    }

    private static let placeholderPrayers: [PrayerTimesEntry.Prayer] = [
        .init(key: "fajr", name: "الفجر", time: "5:24 ص", isActive: true),
        .init(key: "sunrise", name: "الشروق", time: "6:51 ص", isActive: false),
        .init(key: "dhuhr", name: "الظهر", time: "12:45 م", isActive: false),
        .init(key: "asr", name: "العصر", time: "4:05 م", isActive: false),
        .init(key: "maghrib", name: "المغرب", time: "6:36 م", isActive: false),
        .init(key: "isha", name: "العشاء", time: "7:53 م", isActive: false)
    ]

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        completion(buildEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let now = Date()
        let calendar = Self.displayCalendar()

        var entries: [PrayerTimesEntry] = []
        if let blob = Self.loadTimesBlob() {
            let todayKey = Self.dayKey(for: now, calendar: calendar)
            let dayKeys = blob.keys.filter { $0 >= todayKey }.sorted()
            entries = dayKeys.compactMap { key -> PrayerTimesEntry? in
                guard let dayStart = Self.dayStart(fromKey: key, calendar: calendar),
                      let times = blob[key] else { return nil }
                return buildEntry(at: dayStart, times: times)
            }
        }

        if entries.isEmpty {
            // No usable snapshot (app never ran or the stored days all passed).
            entries = [buildEntry(at: now)]
        }

        completion(Timeline(entries: entries, policy: .after(Self.nextRefreshDate(entries, now: now))))
    }

    /// When WidgetKit should ask again.
    ///
    /// Today's entry schedules its own follow-up so the countdown is not left
    /// stale for the rest of the day, capped by `maxRefreshMinutes` and never
    /// past midnight (where the next day's entry takes over).
    private static func nextRefreshDate(
        _ entries: [PrayerTimesEntry],
        now: Date
    ) -> Date {
        let calendar = Self.displayCalendar()
        let midnight = calendar.date(byAdding: .day, value: 1,
                                     to: calendar.startOfDay(for: now)) ?? now

        guard let today = entries.first,
              Self.dayKey(for: today.date, calendar: calendar)
                  == Self.dayKey(for: now, calendar: calendar),
              let remaining = today.remainingMinutes, remaining > 0 else {
            return min(now.addingTimeInterval(Double(maxRefreshMinutes) * 60), midnight)
        }

        let untilCountdownChanges = now.addingTimeInterval(Double(remaining) * 60)
        let capped = now.addingTimeInterval(Double(maxRefreshMinutes) * 60)
        return min(untilCountdownChanges, capped, midnight)
    }

    /// Reads and decodes the rolling multi-day times snapshot written by the
    /// Flutter app: `{"yyyy-MM-dd": {"fajr": "...", ..., "hijri": "...", ...}}`.
    private static func loadTimesBlob() -> [String: [String: String]]? {
        guard let json = UserDefaults(suiteName: suiteName)?.string(forKey: timesJsonKey),
              let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: [String: String]]
    }

    /// The IANA timezone the app computed the prayer times in (its display
    /// timezone): the picked city's zone, or the device's zone on auto.
    ///
    /// WidgetKit has no way to infer it from the wall-clock strings alone, and
    /// judging "now" with the device clock would shift the next-prayer decision
    /// and countdown by the whole offset when the phone is in another timezone
    /// (picked city while traveling, or a mismatched device). When the key is
    /// absent or unknown, falls back to the device calendar.
    private static func displayCalendar() -> Calendar {
        guard let zoneName = UserDefaults(suiteName: suiteName)?
            .string(forKey: "widget_timezone"),
            !zoneName.isEmpty,
            let zone = TimeZone(identifier: zoneName) else { return .current }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    private static func dayStart(fromKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    private func buildEntry(at date: Date, times: [String: String]? = nil) -> PrayerTimesEntry {
        let defaults = UserDefaults(suiteName: Self.suiteName)
        let calendar = Self.displayCalendar()
        let isToday = Self.dayKey(for: date, calendar: calendar)
            == Self.dayKey(for: Date(), calendar: calendar)
        let nowMinutes = isToday ? Self.currentMinutesSinceMidnight(calendar) : -1

        var nextPrayerName = ""
        var bestKey: String?
        var bestDiff = Int.max
        var prayers: [PrayerTimesEntry.Prayer] = []
        var countdownTargets: [String: Date] = [:]

        for key in Self.prayerKeys {
            let raw = times?[key] ?? defaults?.string(forKey: "prayer_\(key)") ?? ""
            let displayTime = raw.isEmpty ? "--:--" : raw
            let name = Self.arabicNames[key] ?? key

            if displayTime != "--:--" {
                // Absolute next occurrence of this prayer's time, computed for
                // EVERY day (not only today) so a pre-built future-day entry
                // still carries a live countdown from the first render after
                // midnight, before WidgetKit asks for a reload.
                if let h24 = timeToH24(raw) {
                    var comps = calendar.dateComponents([.year, .month, .day], from: date)
                    comps.hour = h24.hour
                    comps.minute = h24.minute
                    comps.second = 0
                    var target = calendar.date(from: comps) ?? date
                    if target <= Date() {
                        target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
                    }
                    countdownTargets[key] = target
                }

                if isToday, let pm = parseTimeToMinutes(raw) {
                    // The next prayer is the SMALLEST positive minutes-from-now.
                    // Scanning the canonical order for the first future time only
                    // works while times stay chronologically sorted; a manual
                    // override (e.g. maghrib moved earlier than asr) reorders the
                    // day, so the first future entry is not necessarily the soonest
                    // adhan.
                    var diff = pm - nowMinutes
                    if diff <= 0 { diff += 24 * 60 } // wrapped to tomorrow
                    if diff < bestDiff {
                        bestDiff = diff
                        nextPrayerName = name
                        bestKey = key
                    }
                }
            }

            prayers.append(.init(key: key, name: name, time: displayTime, isActive: false))
        }

        // The mint highlight marks exactly one card: the final countdown
        // leader. Deciding it inside the loop stamped every prayer that ever
        // held the running lead — Fajr most of all, since as the first
        // candidate it always takes the initial lead — leaving Fajr and the
        // real next prayer highlighted together for most of the day.
        if isToday, let activeKey = bestKey,
           let activeIndex = prayers.firstIndex(where: { $0.key == activeKey }) {
            let prayer = prayers[activeIndex]
            prayers[activeIndex] = .init(key: prayer.key, name: prayer.name,
                                         time: prayer.time, isActive: true)
        }

        // Minutes left until the next prayer. `bestDiff` already wraps past
        // midnight, so the countdown never turns negative.
        var remaining: Int?
        if isToday {
            if bestDiff != Int.max { remaining = bestDiff }
            if let value = remaining, value <= 0 { remaining = nil }
        }

        if nextPrayerName.isEmpty {
            // With no prayer left today, wrap to fajr; future-day entries show
            // the first prayer with no active highlight.
            nextPrayerName = Self.arabicNames[Self.prayerKeys[0]] ?? ""
        }

        let hijri = times?["hijri"] ?? defaults?.string(forKey: "hijri_date") ?? ""
        let gregorian = times?["gregorian"] ?? defaults?.string(forKey: "gregorian_date") ?? ""

        return PrayerTimesEntry(
            date: date,
            // The app formats these with Latin digits; convert them the same way
            // as the prayer times so the header matches the rest of the widget.
            hijriText: arabicDigits(hijri),
            gregorianText: arabicDigits(gregorian),
            prayerTimes: prayers,
            nextPrayerName: nextPrayerName,
            countdownText: formatCountdown(remaining),
            remainingMinutes: remaining,
            countdownTargets: countdownTargets
        )
    }

    /// Matches the in-app card with Eastern Arabic numerals.
    ///
    /// Deliberately omits seconds even though the reference design shows
    /// `3:35:47`: a seconds field can only ever read `:00` here, so displaying
    /// one would advertise a precision this platform cannot deliver.
    private func formatCountdown(_ minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "--:--" }
        let hours = minutes / 60
        let mins = minutes % 60
        let text = hours > 0 ? String(format: "%d:%02d", hours, mins) : String(format: "%d:%02d", mins, 0)
        return arabicDigits(text)
    }

    private static func currentMinutesSinceMidnight(_ calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: Date())
        return components.hour! * 60 + components.minute!
    }

    private func timeToH24(_ time: String) -> (hour: Int, minute: Int)? {
        let cleaned = time.trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return nil }

        let isPM = cleaned.contains("م")
        let timePart = cleaned.replacingOccurrences(of: "[صم\\s]", with: "", options: .regularExpression)
        let parts = timePart.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        var h24 = hour
        if isPM && hour != 12 { h24 += 12 }
        if !isPM && hour == 12 { h24 = 0 }

        return (h24, minute)
    }

    private func parseTimeToMinutes(_ time: String) -> Int? {
        guard let h24 = timeToH24(time) else { return nil }
        return h24.hour * 60 + h24.minute
    }

    private func arabicDigits(_ value: String) -> String {
        let digits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(value.map { ch in
            if ch.isASCII, let digit = ch.wholeNumberValue, digit < digits.count {
                return digits[digit]
            }
            return ch
        })
    }
}
