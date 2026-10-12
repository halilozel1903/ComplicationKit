import Foundation
import Testing
@testable import ComplicationKit

@Suite("ComplicationTimeline")
struct ComplicationTimelineTests {
    let now = utcDate(2026, 10, 7, 9, 41, 30)
    let end = utcDate(2026, 10, 7, 9, 45)

    @Test func countdownChangesOnTheMinute() {
        let entries = ComplicationTimeline.countdownEntries(to: end, every: 60, clock: .fixed(now))
        let expected = [
            now,
            utcDate(2026, 10, 7, 9, 42),
            utcDate(2026, 10, 7, 9, 43),
            utcDate(2026, 10, 7, 9, 44),
            end,
        ]
        #expect(entries.map(\.date) == expected)
        #expect(entries.allSatisfy { $0.startDate == now && $0.endDate == end })
        #expect(entries.last?.isFinished == true)
        #expect(entries.dropLast().allSatisfy { !$0.isFinished })
    }

    @Test func noDuplicateWhenNowIsOnABoundary() {
        let onTheMinute = utcDate(2026, 10, 7, 9, 42)
        let entries = ComplicationTimeline.countdownEntries(to: end, every: 60, clock: .fixed(onTheMinute))
        #expect(entries.count == 4)
        #expect(entries.first?.date == onTheMinute)
        #expect(Set(entries.map(\.date)).count == entries.count)
    }

    @Test func maximumCountKeepsTheEarliestEntries() {
        let entries = ComplicationTimeline.countdownEntries(to: end, every: 60, maximumCount: 3, clock: .fixed(now))
        let expected = [now, utcDate(2026, 10, 7, 9, 42), utcDate(2026, 10, 7, 9, 43)]
        #expect(entries.map(\.date) == expected)
        #expect(ComplicationTimeline.reloadDate(after: entries) == utcDate(2026, 10, 7, 9, 43))
        #expect(ComplicationTimeline.countdownEntries(to: end, maximumCount: 0, clock: .fixed(now)).isEmpty)
    }

    @Test func finishedCountdownNeedsNoReload() {
        let full = ComplicationTimeline.countdownEntries(to: end, every: 60, clock: .fixed(now))
        #expect(ComplicationTimeline.reloadDate(after: full) == nil)

        let late = utcDate(2026, 10, 7, 10, 0)
        let over = ComplicationTimeline.countdownEntries(to: end, clock: .fixed(late))
        #expect(over.count == 1)
        #expect(over.first?.isFinished == true)
        #expect(over.first?.remaining == 0)
        #expect(ComplicationTimeline.reloadDate(after: over) == nil)
        #expect(ComplicationTimeline.reloadDate(after: []) == nil)
    }

    @Test func invalidIntervalGivesOneEntry() {
        #expect(ComplicationTimeline.countdownEntries(to: end, every: 0, clock: .fixed(now)).count == 1)
        #expect(ComplicationTimeline.countdownEntries(to: end, every: -60, clock: .fixed(now)).count == 1)
        #expect(ComplicationTimeline.countdownEntries(to: end, every: .nan, clock: .fixed(now)).count == 1)
    }

    @Test func explicitStartDateDrivesProgress() {
        let start = utcDate(2026, 10, 7, 9, 40)
        let entries = ComplicationTimeline.countdownEntries(from: start, to: end, every: 60, clock: .fixed(now))
        // 90 of 300 seconds have passed at 9:41:30.
        #expect(isClose(entries[0].progress, 0.3))
        #expect(isClose(entries[0].remainingFraction, 0.7))
        #expect(entries[0].remaining == 210)
        #expect(entries.last?.progress == 1)
    }

    @Test func hourlyDates() {
        let dates = ComplicationTimeline.hourlyDates(count: 3, clock: .fixed(now), calendar: utcCalendar)
        let expected = [now, utcDate(2026, 10, 7, 10, 0), utcDate(2026, 10, 7, 11, 0)]
        #expect(dates == expected)
        #expect(ComplicationTimeline.hourlyDates(count: 0, clock: .fixed(now), calendar: utcCalendar).isEmpty)
        #expect(ComplicationTimeline.hourlyDates(count: 1, clock: .fixed(now), calendar: utcCalendar) == [now])
    }

    @Test func hourlyEntries() {
        let hours = ComplicationTimeline.hourlyEntries(count: 3, clock: .fixed(now), calendar: utcCalendar) { date in
            utcCalendar.component(.hour, from: date)
        }
        let expected = [9, 10, 11]
        #expect(hours == expected)
    }

    @Test func nextHour() {
        #expect(ComplicationTimeline.nextHour(after: now, calendar: utcCalendar) == utcDate(2026, 10, 7, 10, 0))
        let onTheHour = utcDate(2026, 10, 7, 10, 0)
        #expect(ComplicationTimeline.nextHour(after: onTheHour, calendar: utcCalendar) == utcDate(2026, 10, 7, 11, 0))
        let lateEvening = utcDate(2026, 10, 7, 23, 59, 59)
        #expect(ComplicationTimeline.nextHour(after: lateEvening, calendar: utcCalendar) == utcDate(2026, 10, 8, 0, 0))
    }

    @Test func clocks() {
        let fixed: FixedComplicationClock = .fixed(now)
        #expect(fixed.now == now)
        let before = Date()
        let system = SystemComplicationClock().now
        #expect(system >= before)
    }
}

@Suite("ComplicationRelevance")
struct ComplicationRelevanceTests {
    @Test func countdownScore() {
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 3_600), 0.1))
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 900), 0.1))
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 450), 0.55))
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 1), 1 - 0.9 / 900))
        #expect(ComplicationRelevance.countdownScore(remaining: 0) == 0)
        #expect(ComplicationRelevance.countdownScore(remaining: -10) == 0)
        #expect(ComplicationRelevance.countdownScore(remaining: .nan) == 0)
    }

    @Test func countdownScoreOptions() {
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 30, window: 60, baseline: 0), 0.5))
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 30, window: 0, baseline: 0.2), 0.2))
        #expect(isClose(ComplicationRelevance.countdownScore(remaining: 5_000, baseline: 3), 1))
    }

    @Test func goalScore() {
        #expect(isClose(ComplicationRelevance.goalScore(progress: 0), 1))
        #expect(isClose(ComplicationRelevance.goalScore(progress: 0.5), 0.55))
        #expect(isClose(ComplicationRelevance.goalScore(progress: 1), 0.1))
        #expect(isClose(ComplicationRelevance.goalScore(progress: 4), 0.1))
        #expect(isClose(ComplicationRelevance.goalScore(progress: .nan), 1))
    }

    @Test func entryScoreRisesTowardsTheEnd() {
        let end = utcDate(2026, 10, 7, 9, 45)
        let entries = ComplicationTimeline.countdownEntries(to: end, every: 60, clock: .fixed(utcDate(2026, 10, 7, 9, 0)))
        let scores = entries.map(\.relevanceScore)
        #expect(zip(scores, scores.dropFirst()).dropLast().allSatisfy { $0 <= $1 })
        #expect(scores.last == 0)
    }
}
