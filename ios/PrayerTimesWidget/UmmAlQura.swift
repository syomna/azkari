import Foundation

/// Faithful port of the `hijri_date` 1.1.0 Dart package (Umm al-Qura calendar)
/// so the widget's dates always match what the app shows.
enum UmmAlQura {
    // weekDay convention: 1 = Monday ... 7 = Sunday (Dart Calendar weekday).
    static let arabicWeekdays = [
        1: "الإثنين",
        2: "الثلاثاء",
        3: "الأربعاء",
        4: "الخميس",
        5: "الجمعة",
        6: "السبت",
        7: "الأحد",
    ]

    static let arabicMonths = [
        0: "",
        1: "محرم",
        2: "صفر",
        3: "ربيع الاول",
        4: "ربيع الثاني",
        5: "جمادى الأول",
        6: "جمادى الثاني",
        7: "رجب",
        8: "شعبان",
        9: "رمضان",
        10: "شوال",
        11: "ذو القعدة",
        12: "ذو الحجة",
    ]

    static let gregorianMonths = [
        0: "",
        1: "يناير",
        2: "فبراير",
        3: "مارس",
        4: "أبريل",
        5: "مايو",
        6: "يونيو",
        7: "يوليو",
        8: "أغسطس",
        9: "سبتمبر",
        10: "أكتوبر",
        11: "نوفمبر",
        12: "ديسمبر",
    ]

    /// Converts a Gregorian date to the Umm al-Qura Hijri date.
    /// Returns `nil` when the date is outside the table span (1356-1500 AH).
    static func hijri(
        from date: Date
    ) -> (day: Int, month: Int, year: Int, weekday: Int)? {
        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month,
            let day = comps.day else { return nil }
        return hijri(year: year, month: month, day: day)
    }

    /// Direct port of `HijriDate.gregorianToHijri`.
    static func hijri(
        year pYear: Int, month pMonth: Int, day pDay: Int
    ) -> (day: Int, month: Int, year: Int, weekday: Int)? {
        var m = pMonth
        var y = pYear
        if m < 3 {
            y -= 1
            m += 12
        }

        let a0 = y / 100
        let jgc = a0 - (a0 / 4) - 2

        let cjdn =
            Int((365.25 * Double(y + 4716)).rounded(.down))
            + Int((30.6001 * Double(m + 1)).rounded(.down))
            + pDay - jgc - 1524

        let mcjdn = cjdn - 2400000

        let values = UmmAlQuraData.values
        guard mcjdn >= values[0] && mcjdn < values[values.count - 1] else {
            return nil
        }

        var i = 0
        while i < values.count && values[i] <= mcjdn { i += 1 }
        guard i > 0 && i < values.count else { return nil }

        let iln = i + 16260
        let ii = (iln - 1) / 12
        let iy = ii + 1
        let im = iln - 12 * ii
        let id = mcjdn - values[i - 1] + 1

        var weekday = (cjdn + 1) % 7
        if weekday == 0 { weekday = 7 }

        return (id, im, iy, weekday)
    }

    /// The widget header strings, mirroring PrayerTimesWidgetService in Dart:
    /// text = "<hijriDayName>، <day> <hijriMonthName> <year>".
    static func hijriDateString(for date: Date) -> String {
        guard let h = hijri(from: date),
            let dayName = arabicWeekdays[h.weekday],
            let monthName = arabicMonths[h.month] else { return "" }
        return "\(dayName)، \(h.day) \(monthName) \(h.year)"
    }

    /// Gregorian header: "<dayName> <day> <monthName> <year>".
    static func gregorianDateString(for date: Date) -> String {
        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = comps.year, let month = comps.month,
            let day = comps.day, let swiftWeekday = comps.weekday else { return "" }
        // Foundation weekday: 1 = Sunday ... 7 = Saturday. Convert to Monday=1.
        let wk = ((swiftWeekday + 5) % 7) + 1
        return "\(arabicWeekdays[wk] ?? "") \(day) \(gregorianMonths[month] ?? "") \(year)"
    }
}