import WidgetKit
import SwiftUI

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("عرض مواقيت الصلاة على الشاشة الرئيسية")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
