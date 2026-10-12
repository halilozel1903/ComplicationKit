import ComplicationKit
import SwiftUI
import WidgetKit

/// Today's water at one moment.
struct HydrateEntry: TimelineEntry, Sendable {
    let date: Date
    let day: HydrateDay

    /// The Smart Stack shows the widget more readily while the goal is still far away.
    var relevance: TimelineEntryRelevance? {
        .complication(score: ComplicationRelevance.goalScore(progress: day.progress), duration: 3_600)
    }
}

/// One entry now and one at the start of each of the next hours, because the chart has one bar per hour.
struct HydrateProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrateEntry {
        HydrateEntry(date: HydrateSchedule.previewDate, day: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrateEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let now = Date.now
            completion(HydrateEntry(date: now, day: .sample(at: now)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrateEntry>) -> Void) {
        let timeline: Timeline<HydrateEntry> = .hourly(count: 12) { date in
            HydrateEntry(date: date, day: .sample(at: date))
        }
        completion(timeline)
    }
}

struct HydrateProgressWidget: Widget {
    let kind = "HydrateProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrateProgressProvider()) { entry in
            HydrateProgressComplication(day: entry.day)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Water today")
        .description("How much you have drunk today, towards your daily goal.")
        .supportedFamilies(ComplicationFamily.widgetFamilies)
    }
}
