import SwiftUI
import WidgetKit

/// Fixed palette for the home-screen widget.
///
/// The design is a dark forest-green container, so there is no light variant
/// and nothing to sync with the app's appearance setting.
enum WidgetTheme {
    /// Rich dark forest green container.
    static let background = Color(red: 0.086, green: 0.294, blue: 0.204) // #164B34
    /// Translucent white slots; the container shows through.
    static let cell = Color.white.opacity(0.12)
    static let cellBorder = Color.white.opacity(0.10)
    /// Soft pastel mint for the expanded active-prayer card.
    static let activeCard = Color(red: 0.867, green: 0.945, blue: 0.894) // #DDF1E4
    /// Dark green for text and icons on the mint card.
    static let accent = Color(red: 0.078, green: 0.420, blue: 0.235) // #146B3C
    static let accentMuted = accent.opacity(0.65)
    static let divider = accent.opacity(0.18)
    static let text = Color.white
    static let textMuted = Color.white.opacity(0.72)

    /// SF Symbol per prayer, matching the reference design: sparkles for Fajr,
    /// sun on the horizon for Sunrise, sun for Duhr and Asr, sunset for
    /// Maghrib, crescent and star for Isha.
    static func icon(for key: String) -> String {
        switch key {
        case "fajr": return "sparkles"
        case "sunrise": return "sun.horizon.fill"
        case "dhuhr", "asr": return "sun.max.fill"
        case "maghrib": return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }
}

struct PrayerTimesWidgetView: View {
    var entry: PrayerTimesEntry

    private let padding: CGFloat = 10
    private let gap: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - padding * 2
            let slotWidth = (usable - gap * 2) / 3

            VStack(spacing: gap) {
                PrayerTimesHeader(entry: entry)

                HStack(spacing: gap) {
                    ForEach(0..<3, id: \.self) { i in
                        CompactPrayerCard(entry: entry, index: i)
                            .frame(width: slotWidth)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: gap) {
                    ForEach(3..<6, id: \.self) { i in
                        CompactPrayerCard(entry: entry, index: i)
                            .frame(width: slotWidth)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: gap) {
                    Text("باقي حتى \(entry.nextPrayerName)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(WidgetTheme.textMuted)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    TimelineView(.periodic(from: Date(), by: 1)) { context in
                        Text(PrayerTimesWidgetView.liveCountdown(entry: entry, reference: context.date))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(WidgetTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .padding(.horizontal, WidgetMetrics.compactPadding)
                .padding(.vertical, 4)
            }
            .padding(padding)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .containerBackground(for: .widget) { WidgetTheme.background }
    }
}

/// Hijri date on the leading edge, gregorian trailing it. Both are supplied by
/// the app snapshot for the same day as the prayer times below.
/// Insets that both the cards and the date header depend on.
///
/// The header lines its outer edges up with the text inside the outermost
/// cards, so these are named once and referenced from both.
enum WidgetMetrics {
    static let activePadding: CGFloat = 9
    static let compactPadding: CGFloat = 7
}

struct PrayerTimesHeader: View {
    let entry: PrayerTimesEntry

    var body: some View {
        HStack(spacing: 6) {
            Text(entry.hijriText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(WidgetTheme.text)
                .lineLimit(1)
                // Leading edge is the wide active card's side.
                .padding(.leading, WidgetMetrics.activePadding)

            Spacer(minLength: 0)

            Text(entry.gregorianText)
                .font(.system(size: 8.5))
                .foregroundColor(WidgetTheme.textMuted)
                .lineLimit(1)
                // Trailing edge is a compact card's side.
                .padding(.trailing, WidgetMetrics.compactPadding)
        }
        // The two labels share one line, so the shorter one has to be able to
        // shrink rather than push the other off the edge.
        .minimumScaleFactor(0.8)
    }
}

/// The prayer whose adhan is next: a wide mint card pairing its own time with
/// the countdown, so both facts live together.
struct ActivePrayerCard: View {
    let entry: PrayerTimesEntry

    private var prayer: PrayerTimesEntry.Prayer {
        entry.orderedPrayers.first ?? PrayerTimesEntry.Prayer(
            key: "fajr", name: "", time: "", isActive: true)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: WidgetTheme.icon(for: prayer.key))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(prayer.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(WidgetTheme.accent)
                    .lineLimit(1)

                Text(PrayerTimesWidgetView.arabicDigits(prayer.time))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WidgetTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(WidgetTheme.divider)
                .frame(width: 1, height: 24)

            // Countdown block, right of the prayer time.
            VStack(alignment: .trailing, spacing: 1) {
                Text("باقي حتى \(entry.nextPrayerName)")
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(WidgetTheme.accentMuted)
                    .lineLimit(1)

                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    Text(PrayerTimesWidgetView.liveCountdown(entry: entry, reference: context.date))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(WidgetTheme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, WidgetMetrics.activePadding)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WidgetTheme.activeCard)
        )
    }
}

/// One of the five compact slots: icon, label, time.
struct CompactPrayerCard: View {
    let entry: PrayerTimesEntry
    let index: Int

    private var prayer: PrayerTimesEntry.Prayer {
        // `index` counts into the display order, so slot 1 is the first prayer
        // after the wide active card rather than the second prayer of the day.
        entry.orderedPrayers.indices.contains(index)
            ? entry.orderedPrayers[index]
            : PrayerTimesEntry.Prayer(key: "", name: "", time: "", isActive: false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: WidgetTheme.icon(for: prayer.key))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(prayer.isActive ? WidgetTheme.accent : WidgetTheme.text)

            Text(prayer.name)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(prayer.isActive ? WidgetTheme.accent : WidgetTheme.textMuted)
                .lineLimit(1)
                .padding(.top, 3)

            Text(PrayerTimesWidgetView.arabicDigits(prayer.time))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(prayer.isActive ? WidgetTheme.accent : WidgetTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, WidgetMetrics.compactPadding)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(prayer.isActive ? WidgetTheme.activeCard : WidgetTheme.cell)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(prayer.isActive ? WidgetTheme.accent.opacity(0.4) : WidgetTheme.cellBorder, lineWidth: 1)
        )
    }
}

extension PrayerTimesWidgetView {
    static func liveCountdown(entry: PrayerTimesEntry, reference: Date) -> String {
        var bestTarget: Date?
        for (_, t) in entry.countdownTargets {
            if t > reference {
                if let b = bestTarget {
                    if t < b { bestTarget = t }
                } else {
                    bestTarget = t
                }
            }
        }
        guard let target = bestTarget else { return entry.countdownText }
        let diff = max(0, Int(target.timeIntervalSince(reference)))
        let hours = diff / 3600
        let mins = (diff / 60) % 60
        let secs = diff % 60
        let s: String = hours > 0
            ? String(format: "%d:%02d:%02d", hours, mins, secs)
            : String(format: "%d:%02d", mins, secs)
        return arabicDigits(s)
    }

    /// Matches the app, which formats times and countdowns with Eastern Arabic
    /// numerals.
    static func arabicDigits(_ value: String) -> String {
        let digits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(value.map { ch in
            if ch.isASCII, let digit = ch.wholeNumberValue, digit < digits.count {
                return digits[digit]
            }
            return ch
        })
    }
}

struct PrayerTimesWidgetView_Previews: PreviewProvider {
    private static let sample = PrayerTimesEntry(
        date: Date(),
        hijriText: "5 ربيع الآخر 1447 هـ",
        gregorianText: "الثلاثاء 5 يناير 2026",
        prayerTimes: [
            .init(key: "fajr", name: "الفجر", time: "5:24 ص", isActive: true),
            .init(key: "sunrise", name: "الشروق", time: "6:51 ص", isActive: false),
            .init(key: "dhuhr", name: "الظهر", time: "12:45 م", isActive: false),
            .init(key: "asr", name: "العصر", time: "4:05 م", isActive: false),
            .init(key: "maghrib", name: "المغرب", time: "6:36 م", isActive: false),
            .init(key: "isha", name: "العشاء", time: "7:53 م", isActive: false)
        ],
        nextPrayerName: "الفجر",
        countdownText: "3:35",
        remainingMinutes: 215,
        countdownTargets: [:]
    )

    static var previews: some View {
        PrayerTimesWidgetView(entry: sample)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
