import ComplicationKit
import SwiftUI

// The fictional Hydrate water tracker, shared by the gallery app and the widget extension so the gallery shows
// exactly what the complications on a real watch face show. All numbers are made up.

extension Color {
    /// Hydrate's water blue.
    static let hydrate = Color(red: 0.22, green: 0.78, blue: 1.0)
    /// The deep end of Hydrate's gradients.
    static let hydrateDeep = Color(red: 0.16, green: 0.42, blue: 1.0)
}

/// One day of drinking water: how much was drunk in each hour from 6 AM to 10 PM.
struct HydrateDay: Hashable, Sendable {
    /// The hour of the first slot.
    static let firstHour = 6
    /// Liters per hour for a whole day, 6 AM to 10 PM.
    static let pattern: [Double] = [0.3, 0.25, 0.35, 0.2, 0.1, 0.3, 0.15, 0.2, 0.25, 0.1, 0.2, 0.15, 0.1, 0.2, 0.1, 0.05, 0]
    /// The daily goal in liters.
    static let dailyGoal = 2.5

    /// Liters per hour so far; hours still to come are zero.
    var hourly: [Double]
    /// The slot of the current hour, or `nil` outside 6 AM to 10 PM.
    var currentIndex: Int?
    /// The goal in liters.
    var goal: Double = HydrateDay.dailyGoal

    /// Liters drunk today.
    var consumed: Double { hourly.reduce(0, +) }
    /// The share of the goal reached, from 0 to 1.
    var progress: Double { ComplicationValue.progress(consumed, goal: goal) }
    /// "1.2"
    var consumedText: String { CompactNumber.string(consumed) }
    /// "2.5"
    var goalText: String { CompactNumber.string(goal) }

    /// The day as it is at `date`.
    static func sample(at date: Date, calendar: Calendar = .current) -> HydrateDay {
        let index = calendar.component(.hour, from: date) - firstHour
        let hourly = pattern.indices.map { $0 <= index ? pattern[$0] : 0 }
        return HydrateDay(hourly: hourly, currentIndex: pattern.indices.contains(index) ? index : nil)
    }

    /// The day at 10:09, as in the screenshots: 1.2 of 2.5 liters.
    static let preview = HydrateDay.sample(at: HydrateSchedule.previewDate)
}

/// Hydrate reminds you to drink every hour at half past.
enum HydrateSchedule {
    /// The time between two reminders.
    static let interval: TimeInterval = 3_600
    /// Where in the hour a reminder fires.
    static let offset: TimeInterval = 1_800

    /// The reminder before `date` (or at it) and the next one, as the start and end of an interval.
    static func reminder(around date: Date, calendar: Calendar = .current) -> DateInterval {
        let hour = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        var previous = hour.addingTimeInterval(offset)
        if previous > date {
            previous = previous.addingTimeInterval(-interval)
        }
        return DateInterval(start: previous, end: previous.addingTimeInterval(interval))
    }

    /// 10:09 on October 7, 2026, the moment shown in the screenshots.
    static var previewDate: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 10, minute: 9))
            ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    /// The countdown at `previewDate`: 21 minutes to the 10:30 reminder.
    static var previewEntry: CountdownEntry {
        let current = reminder(around: previewDate)
        return CountdownEntry(date: previewDate, startDate: current.start, endDate: current.end)
    }
}

/// Today's water in every accessory family: a ring, a curved gauge, an hourly chart and a line of text.
struct HydrateProgressComplication: View {
    let day: HydrateDay

    var body: some View {
        ComplicationFamilyView {
            CircularRingComplication(progress: day.progress, valueText: day.consumedText, symbolName: "drop.fill", tint: .hydrate)
        } corner: {
            CornerGaugeComplication(
                value: day.consumed,
                in: 0...max(day.goal, 0.1),
                symbolName: "drop.fill",
                trailingText: day.goalText + "L",
                colors: [.hydrateDeep, .hydrate]
            )
        } rectangular: {
            RectangularChartComplication(
                title: "Hydrate",
                symbolName: "drop.fill",
                valueText: "\(day.consumedText) / \(day.goalText) L",
                values: day.hourly,
                maximum: HydrateDay.pattern.max(),
                highlightedIndex: day.currentIndex,
                leadingAxisText: "6AM",
                trailingAxisText: "10PM",
                tint: .hydrate
            )
        } inline: {
            InlineComplication(
                symbolName: "drop.fill",
                text: "\(day.consumedText) of \(day.goalText) L",
                compactText: "\(day.consumedText) L"
            )
        }
    }
}

/// The countdown to the next glass in every accessory family.
struct HydrateReminderComplication: View {
    let entry: CountdownEntry

    /// "21m", or "NOW" once the reminder is due.
    private var shortText: String {
        entry.isFinished ? "NOW" : CompactTime.shortest(entry.remaining)
    }

    /// "in 21m", or "now".
    private var longText: String {
        entry.isFinished ? "now" : "in " + CompactTime.abbreviated(entry.remaining)
    }

    var body: some View {
        ComplicationFamilyView {
            CircularStackComplication(top: .symbol("bell.fill"), value: shortText, bottom: "SIP", tint: .hydrate)
        } corner: {
            CornerTextComplication(symbolName: "bell.fill", label: shortText.uppercased(), tint: .hydrate)
        } rectangular: {
            RectangularTextComplication(
                title: "Next sip",
                symbolName: "bell.fill",
                headline: longText,
                detail: "250 ml at " + entry.endDate.formatted(date: .omitted, time: .shortened),
                progress: entry.progress,
                tint: .hydrate
            )
        } inline: {
            InlineComplication(symbolName: "bell.fill", text: "Sip \(longText)", compactText: "Sip \(shortText)")
        }
    }
}
