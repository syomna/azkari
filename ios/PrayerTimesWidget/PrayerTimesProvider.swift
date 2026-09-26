import WidgetKit
import SwiftUI

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [(name: String, time: String, isActive: Bool)]
    let nextPrayerName: String
    let hijriDate: String
    let gregorianDate: String
}

struct PrayerTimesProvider: TimelineProvider {
    static let suiteName = "group.com.yomna.azkarApp"
    static let timesJsonKey = "widget_times_json"

    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            prayerTimes: [
                (name: "الفجر", time: "4:30 ص", isActive: false),
                (name: "الشروق", time: "6:00 ص", isActive: false),
                (name: "الظهر", time: "12:15 م", isActive: true),
                (name: "العصر", time: "3:45 م", isActive: false),
                (name: "المغرب", time: "6:30 م", isActive: false),
                (name: "العشاء", time: "8:00 م", isActive: false)
            ],
            nextPrayerName: "الظهر",
            hijriDate: "15 رمضان 1447",
            gregorianDate: "الجمعة 21 يوليو 2025"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        let entry = buildEntry(at: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current

        if let blob = Self.loadTimesBlob() {
            let todayKey = Self.dayKey(for: now, calendar: calendar)
            let dayKeys = blob.keys.filter { $0 >= todayKey }.sorted()
            let entries = dayKeys.compactMap { key -> PrayerTimesEntry? in
                guard let dayStart = Self.dayStart(fromKey: key, calendar: calendar),
                      let times = blob[key] else { return nil }
                return buildEntry(at: dayStart, times: times)
            }

            if !entries.isEmpty, let lastDate = entries.last?.date,
               let refresh = calendar.date(byAdding: .day, value: 1,
                                           to: calendar.startOfDay(for: lastDate)) {
                completion(Timeline(entries: entries, policy: .after(refresh)))
                return
            }
        }

        // No usable snapshot (app never ran or the stored days all passed):
        // fall back to a single entry refreshed on the usual cadence.
        let entry = buildEntry(at: now)
        let nextUpdate = calendar.date(byAdding: .minute, value: 15, to: now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    /// Reads and decodes the rolling multi-day times snapshot written by the
    /// Flutter app: `{"yyyy-MM-dd": {"fajr": "...", ..., "hijri": "...", ...}}`.
    private static func loadTimesBlob() -> [String: [String: String]]? {
        guard let json = UserDefaults(suiteName: suiteName)?.string(forKey: timesJsonKey),
              let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: [String: String]]
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

        let keys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
        let arabicNames = ["fajr": "الفجر", "sunrise": "الشروق", "dhuhr": "الظهر",
                          "asr": "العصر", "maghrib": "المغرب", "isha": "العشاء"]

        let clock = Calendar.current
        let isToday = clock.isDateInToday(date)
        let nowMinutes = isToday ? currentMinutesSinceMidnight() : -1
        var nextPrayerName = ""
        var prayerTimes: [(name: String, time: String, isActive: Bool)] = []

        for key in keys {
            let time = times?[key] ?? defaults?.string(forKey: "prayer_\(key)") ?? "--:--"
            let name = arabicNames[key] ?? key
            var isActive = false

            if isToday && !time.isEmpty && time != "--:--" {
                let prayerMinutes = parseTimeToMinutes(time)
                if let pm = prayerMinutes, pm > nowMinutes, nextPrayerName.isEmpty {
                    nextPrayerName = name
                    isActive = true
                }
            }

            prayerTimes.append((name: name, time: time.isEmpty ? "--:--" : time, isActive: isActive))
        }

        if nextPrayerName.isEmpty {
            // With no prayer left today, wrap to fajr; future-day entries show
            // the first prayer with no active highlight.
            nextPrayerName = arabicNames[keys[0]] ?? ""
        }

        let fallbackHijri = defaults?.string(forKey: "hijri_date") ?? ""
        let fallbackGregorian = defaults?.string(forKey: "gregorian_date") ?? ""
        // Compute the dates fresh on every timeline refresh instead of showing
        // strings saved on the last app run (which go stale after a day).
        let hijriDate = UmmAlQura.hijriDateString(for: date)
        let gregorianDate = UmmAlQura.gregorianDateString(for: date)

        return PrayerTimesEntry(
            date: date,
            prayerTimes: prayerTimes,
            nextPrayerName: nextPrayerName,
            // Only fall back to the stored strings when the date is outside the
            // Umm al-Qura table span (1356-1500 AH).
            hijriDate: hijriDate.isEmpty ? fallbackHijri : hijriDate,
            gregorianDate: gregorianDate.isEmpty ? fallbackGregorian : gregorianDate
        )
    }

    private func currentMinutesSinceMidnight() -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date())
    }

    private func parseTimeToMinutes(_ time: String) -> Int? {
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

        return h24 * 60 + minute
    }
}