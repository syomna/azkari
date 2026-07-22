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
        let entry = buildEntry(at: now)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func buildEntry(at date: Date) -> PrayerTimesEntry {
        let defaults = UserDefaults(suiteName: "group.com.yomna.azkarApp")

        let keys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
        let arabicNames = ["fajr": "الفجر", "sunrise": "الشروق", "dhuhr": "الظهر",
                          "asr": "العصر", "maghrib": "المغرب", "isha": "العشاء"]

        let nowMinutes = currentMinutesSinceMidnight()
        var nextPrayerKey = keys[0]
        var nextPrayerName = ""
        var prayerTimes: [(name: String, time: String, isActive: Bool)] = []

        for key in keys {
            let time = defaults?.string(forKey: "prayer_\(key)") ?? "--:--"
            let name = arabicNames[key] ?? key
            let isActive: Bool

            if !time.isEmpty && time != "--:--" {
                let prayerMinutes = parseTimeToMinutes(time)
                if let pm = prayerMinutes, pm > nowMinutes, nextPrayerKey == keys[0] && nextPrayerName.isEmpty {
                    nextPrayerKey = key
                    nextPrayerName = name
                }
                isActive = key == nextPrayerKey && !nextPrayerName.isEmpty
            } else {
                isActive = false
            }

            prayerTimes.append((name: name, time: time.isEmpty ? "--:--" : time, isActive: isActive))
        }

        if nextPrayerName.isEmpty {
            nextPrayerKey = keys[0]
            nextPrayerName = arabicNames[keys[0]] ?? ""
        }

        for i in prayerTimes.indices {
            prayerTimes[i].isActive = prayerTimes[i].name == nextPrayerName
        }

        let hijriDate = defaults?.string(forKey: "hijri_date") ?? ""
        let gregorianDate = defaults?.string(forKey: "gregorian_date") ?? ""

        return PrayerTimesEntry(
            date: date,
            prayerTimes: prayerTimes,
            nextPrayerName: nextPrayerName,
            hijriDate: hijriDate,
            gregorianDate: gregorianDate
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
