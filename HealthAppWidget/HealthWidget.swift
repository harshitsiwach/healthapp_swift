import WidgetKit
import SwiftUI

// MARK: - Widget

struct HealthWidget: Widget {
    let kind: String = "com.aihealthappoffline.widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthWidgetProvider()) { entry in
            HealthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Health")
        .description("Track your calories, macros, and health score at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Entry View

struct HealthWidgetEntryView: View {
    let entry: HealthWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    HealthWidget()
} timeline: {
    HealthWidgetEntry.snapshot
}

#Preview("Medium", as: .systemMedium) {
    HealthWidget()
} timeline: {
    HealthWidgetEntry.snapshot
}

#Preview("Large", as: .systemLarge) {
    HealthWidget()
} timeline: {
    HealthWidgetEntry.snapshot
}
