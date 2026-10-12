import ComplicationKit
import SwiftUI
import WidgetKit

/// Counts down to the next reminder, one entry per minute, and asks for a new timeline when the reminder is due.
/// `CountdownEntry` is a `TimelineEntry` whose relevance rises over the last 15 minutes, so the Smart Stack brings
/// the widget forward just before it is time to drink.
struct HydrateReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        HydrateSchedule.previewEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(entries(at: .now).first ?? placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date.now
        let reminder = HydrateSchedule.reminder(around: now)
        completion(Timeline(entries: entries(at: now), policy: .after(reminder.end)))
    }

    private func entries(at now: Date) -> [CountdownEntry] {
        let reminder = HydrateSchedule.reminder(around: now)
        return ComplicationTimeline.countdownEntries(
            from: reminder.start,
            to: reminder.end,
            every: 60,
            clock: FixedComplicationClock(now)
        )
    }
}

struct HydrateReminderWidget: Widget {
    let kind = "HydrateReminder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrateReminderProvider()) { entry in
            HydrateReminderComplication(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Next sip")
        .description("Counts down to your next glass of water.")
        .supportedFamilies(ComplicationFamily.widgetFamilies)
    }
}
