import SwiftUI
import WidgetKit

struct PrayerTimesWidgetView: View {
    var entry: PrayerTimesEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.10),
                    Color(red: 0.02, green: 0.08, blue: 0.15),
                    Color(red: 0.01, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.20),
                    Color.teal.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.hijriDate)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(entry.gregorianDate)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("التالي: \(entry.nextPrayerName)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.green.opacity(0.9))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        PrayerCell(
                            name: entry.prayerTimes[i].name,
                            time: entry.prayerTimes[i].time,
                            isActive: entry.prayerTimes[i].isActive
                        )
                    }
                }
                .padding(.horizontal, 10)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    ForEach(3..<6, id: \.self) { i in
                        PrayerCell(
                            name: entry.prayerTimes[i].name,
                            time: entry.prayerTimes[i].time,
                            isActive: entry.prayerTimes[i].isActive
                        )
                    }
                }
                .padding(.horizontal, 10)

                Spacer(minLength: 0)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct PrayerCell: View {
    let name: String
    let time: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
                .lineLimit(1)

            Text(time)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(isActive ? .white : Color.green.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.7),
                                    Color.teal.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.4), lineWidth: 0.5)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                }
            }
        )
    }
}

struct PrayerTimesWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesWidgetView(entry: PrayerTimesEntry(
            date: Date(),
            prayerTimes: [
                (name: "الفجر", time: "4:30", isActive: false),
                (name: "الشروق", time: "6:00", isActive: false),
                (name: "الظهر", time: "12:15", isActive: true),
                (name: "العصر", time: "3:45", isActive: false),
                (name: "المغرب", time: "6:30", isActive: false),
                (name: "العشاء", time: "8:00", isActive: false)
            ],
            nextPrayerName: "الظهر",
            hijriDate: "15 رمضان 1447",
            gregorianDate: "الجمعة 21 يوليو 2025"
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
