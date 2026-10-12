import Foundation

// MARK: - Clock

/// The source of "now" for timeline generation. Inject a `FixedComplicationClock` in tests and previews so
/// timelines are the same on every run.
public protocol ComplicationClock: Sendable {
    /// The current date.
    var now: Date { get }
}

/// The real clock.
public struct SystemComplicationClock: ComplicationClock {
    public init() {}
    public var now: Date { Date() }
}

/// A clock stopped at one date.
public struct FixedComplicationClock: ComplicationClock {
    public var now: Date

    public init(_ now: Date) {
        self.now = now
    }
}

extension ComplicationClock where Self == SystemComplicationClock {
    /// The real clock.
    public static var system: SystemComplicationClock { SystemComplicationClock() }
}

extension ComplicationClock where Self == FixedComplicationClock {
    /// A clock stopped at `date`.
    public static func fixed(_ date: Date) -> FixedComplicationClock { FixedComplicationClock(date) }
}

// MARK: - Countdown entries

/// One moment of a countdown: what a complication shows at `date` for a countdown that runs from `startDate`
/// to `endDate`. On watchOS and iOS it is a WidgetKit `TimelineEntry`, so you can return it from a provider as is.
public struct CountdownEntry: Hashable, Sendable {
    /// When the entry becomes current.
    public let date: Date
    /// When the countdown started, for the progress.
    public let startDate: Date
    /// When the countdown ends.
    public let endDate: Date

    public init(date: Date, startDate: Date, endDate: Date) {
        self.date = date
        self.startDate = startDate
        self.endDate = endDate
    }

    /// Seconds left at `date`, never negative.
    public var remaining: TimeInterval { max(0, endDate.timeIntervalSince(date)) }

    /// `true` once `date` reaches `endDate`.
    public var isFinished: Bool { date >= endDate }

    /// How much of the countdown has passed at `date`, from 0 at the start to 1 at the end.
    public var progress: Double {
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1 }
        return min(max(date.timeIntervalSince(startDate) / total, 0), 1)
    }

    /// The share of the countdown that is left, from 1 at the start to 0 at the end.
    public var remainingFraction: Double { 1 - progress }

    /// How relevant the entry is for the Smart Stack, from 0 to 1. See `ComplicationRelevance.countdownScore`.
    public var relevanceScore: Double {
        isFinished ? 0 : ComplicationRelevance.countdownScore(remaining: remaining)
    }
}

// MARK: - Timeline generation

/// Builds timeline dates and entries. Everything takes a clock, so the output is predictable in tests.
public enum ComplicationTimeline {
    /// Entries for a countdown to `endDate`: one now, then one each time the remaining time crosses a multiple of
    /// `interval` before the end (so a minute countdown changes exactly on the minute), and a last, finished one at
    /// `endDate`. At most `maximumCount` entries are returned, the earliest ones.
    ///
    /// ```swift
    /// // Now is 9:41:30, the tea is ready at 9:45.
    /// ComplicationTimeline.countdownEntries(to: ready, every: 60, clock: .fixed(now)).map(\.date)
    /// // 9:41:30, 9:42, 9:43, 9:44, 9:45
    /// ```
    public static func countdownEntries<C: ComplicationClock>(
        from startDate: Date? = nil,
        to endDate: Date,
        every interval: TimeInterval = 60,
        maximumCount: Int = 60,
        clock: C = SystemComplicationClock()
    ) -> [CountdownEntry] {
        let now = clock.now
        let start = startDate ?? now
        func entry(_ date: Date) -> CountdownEntry {
            CountdownEntry(date: date, startDate: start, endDate: endDate)
        }
        guard maximumCount > 0 else { return [] }
        guard now < endDate, interval > 0, interval.isFinite, maximumCount > 1 else {
            return [entry(now)]
        }

        var entries = [entry(now)]
        let remaining = endDate.timeIntervalSince(now)
        let steps = (remaining / interval).rounded(.up)
        let boundaries = steps > 1_000_000 ? 1_000_000 : Int(steps)
        // Boundaries are endDate - k * interval for k = boundaries - 1 ... 0, all after now.
        var k = boundaries - 1
        while k >= 0, entries.count < maximumCount {
            entries.append(entry(endDate.addingTimeInterval(-Double(k) * interval)))
            k -= 1
        }
        return entries
    }

    /// The date to ask WidgetKit for a new timeline after `entries`: `nil` (never) when the last entry is a finished
    /// countdown, otherwise the date of the last entry.
    public static func reloadDate(after entries: [CountdownEntry]) -> Date? {
        guard let last = entries.last else { return nil }
        return last.isFinished ? nil : last.date
    }

    /// Now, followed by the start of each of the next `count - 1` hours: 9:41:30, 10:00, 11:00, …
    /// Use it for complications that change through the day, like a weather forecast or a water goal.
    public static func hourlyDates<C: ComplicationClock>(
        count: Int = 24,
        clock: C = SystemComplicationClock(),
        calendar: Calendar = .current
    ) -> [Date] {
        guard count > 0 else { return [] }
        let now = clock.now
        var dates = [now]
        var next = nextHour(after: now, calendar: calendar)
        while dates.count < count {
            dates.append(next)
            next = calendar.date(byAdding: .hour, value: 1, to: next) ?? next.addingTimeInterval(3_600)
        }
        return dates
    }

    /// Entries for `hourlyDates(count:clock:calendar:)`, made by `makeEntry`.
    public static func hourlyEntries<Entry, C: ComplicationClock>(
        count: Int = 24,
        clock: C = SystemComplicationClock(),
        calendar: Calendar = .current,
        makeEntry: (Date) -> Entry
    ) -> [Entry] {
        hourlyDates(count: count, clock: clock, calendar: calendar).map(makeEntry)
    }

    /// The start of the hour after `date`. A date exactly on the hour gives the following hour.
    public static func nextHour(after date: Date, calendar: Calendar = .current) -> Date {
        if let hour = calendar.dateInterval(of: .hour, for: date) {
            return hour.end
        }
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / 3_600).rounded(.down) * 3_600 + 3_600)
    }
}

// MARK: - Relevance

/// Scores for WidgetKit's `TimelineEntryRelevance`, which the Smart Stack on Apple Watch uses to pick a widget.
public enum ComplicationRelevance {
    /// The score of a countdown: low (`baseline`) while the end is far away, rising to 1 over the last `window`
    /// seconds, and 0 once it is over.
    ///
    /// ```swift
    /// ComplicationRelevance.countdownScore(remaining: 3_600)   // 0.1
    /// ComplicationRelevance.countdownScore(remaining: 450)     // 0.55: halfway through the last 15 minutes
    /// ComplicationRelevance.countdownScore(remaining: 0)       // 0
    /// ```
    public static func countdownScore(remaining: TimeInterval, window: TimeInterval = 900, baseline: Double = 0.1) -> Double {
        guard !remaining.isNaN, remaining > 0 else { return 0 }
        let baseline = min(max(baseline, 0), 1)
        guard window > 0, remaining < window else { return baseline }
        return 1 - (1 - baseline) * remaining / window
    }

    /// A score from how far a value is from its goal: 1 when nothing is done yet, falling to `baseline` when the
    /// goal is reached. A water or stand reminder is most useful while the goal is still far.
    public static func goalScore(progress: Double, baseline: Double = 0.1) -> Double {
        let progress = progress.isNaN ? 0 : min(max(progress, 0), 1)
        let baseline = min(max(baseline, 0), 1)
        return baseline + (1 - baseline) * (1 - progress)
    }
}
