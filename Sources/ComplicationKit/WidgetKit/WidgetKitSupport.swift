#if canImport(WidgetKit) && (os(watchOS) || os(iOS))
import Foundation
import WidgetKit

// MARK: - Families

extension ComplicationFamily {
    /// The complication family of a WidgetKit family, or `nil` for the home screen and desktop families.
    public init?(_ family: WidgetFamily) {
        switch family {
        case .accessoryCircular: self = .circular
        case .accessoryRectangular: self = .rectangular
        case .accessoryInline: self = .inline
        #if os(watchOS)
        case .accessoryCorner: self = .corner
        #endif
        default: return nil
        }
    }

    /// The WidgetKit family. `nil` for `.corner` on iOS, which has no corner family.
    public var widgetFamily: WidgetFamily? {
        switch self {
        case .circular: return .accessoryCircular
        case .rectangular: return .accessoryRectangular
        case .inline: return .accessoryInline
        case .corner:
            #if os(watchOS)
            return .accessoryCorner
            #else
            return nil
            #endif
        }
    }

    /// Every accessory family the platform supports, for `supportedFamilies(_:)`.
    public static var widgetFamilies: [WidgetFamily] {
        allCases.compactMap(\.widgetFamily)
    }
}

// MARK: - Countdown timelines

extension CountdownEntry: TimelineEntry {
    /// The relevance WidgetKit and the Smart Stack use to rank the entry. Rises as the countdown nears its end.
    public var relevance: TimelineEntryRelevance? {
        TimelineEntryRelevance(score: Float(relevanceScore), duration: remaining)
    }
}

extension Timeline where EntryType == CountdownEntry {
    /// A timeline for a countdown to `endDate`, built with `ComplicationTimeline.countdownEntries`. It asks for a new
    /// timeline after its last entry, or never once the countdown has finished.
    ///
    /// ```swift
    /// func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
    ///     completion(.countdown(to: timer.endDate, every: 60))
    /// }
    /// ```
    public static func countdown<C: ComplicationClock>(
        from startDate: Date? = nil,
        to endDate: Date,
        every interval: TimeInterval = 60,
        maximumCount: Int = 60,
        clock: C = SystemComplicationClock()
    ) -> Timeline<CountdownEntry> {
        let entries = ComplicationTimeline.countdownEntries(
            from: startDate,
            to: endDate,
            every: interval,
            maximumCount: maximumCount,
            clock: clock
        )
        let policy: TimelineReloadPolicy
        if let reload = ComplicationTimeline.reloadDate(after: entries) {
            policy = .after(reload)
        } else {
            policy = .never
        }
        return Timeline(entries: entries, policy: policy)
    }
}

extension Timeline {
    /// A timeline with an entry now and at the start of each of the next hours, made by `makeEntry`. WidgetKit asks
    /// for a new one after the last entry.
    public static func hourly<C: ComplicationClock>(
        count: Int = 24,
        clock: C = SystemComplicationClock(),
        calendar: Calendar = .current,
        makeEntry: (Date) -> EntryType
    ) -> Timeline<EntryType> {
        let entries = ComplicationTimeline.hourlyEntries(count: count, clock: clock, calendar: calendar, makeEntry: makeEntry)
        return Timeline(entries: entries, policy: .atEnd)
    }
}

extension TimelineEntryRelevance {
    /// A relevance from a score in `0...1` (clamped), as computed by `ComplicationRelevance`.
    public static func complication(score: Double, duration: TimeInterval = 0) -> TimelineEntryRelevance {
        let score = score.isNaN ? 0 : min(max(score, 0), 1)
        return TimelineEntryRelevance(score: Float(score), duration: max(duration, 0))
    }
}
#endif

#if os(watchOS)
import AppIntents
import WidgetKit

// MARK: - Smart Stack relevance

/// Tells the Smart Stack on Apple Watch when a widget configured with an App Intent is relevant, through
/// `RelevantIntentManager` and `RelevantContext`. Static widgets use the `relevance` of their timeline entries
/// instead.
public enum SmartStackRelevance {
    /// A context that makes a widget relevant during `interval`.
    public static func context(for interval: DateInterval) -> RelevantContext {
        RelevantContext.date(from: interval.start, to: interval.end)
    }

    /// Replaces the relevant intents of the app: `intent` for the widget of kind `widgetKind`, relevant during each
    /// of `intervals`, such as the hour before each scheduled drink or the minutes before a timer ends.
    public static func update<Intent: WidgetConfigurationIntent>(
        _ intent: Intent,
        widgetKind: String,
        intervals: [DateInterval]
    ) async throws {
        let relevantIntents = intervals.map { interval in
            RelevantIntent(intent, widgetKind: widgetKind, relevance: context(for: interval))
        }
        try await RelevantIntentManager.shared.updateRelevantIntents(relevantIntents)
    }
}
#endif
