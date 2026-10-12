import Foundation

/// `true` when two doubles are equal up to floating point noise.
func isClose(_ lhs: Double, _ rhs: Double, tolerance: Double = 1e-9) -> Bool {
    abs(lhs - rhs) <= tolerance
}

/// `true` when two arrays of doubles have the same length and pairwise close values.
func isClose(_ lhs: [Double], _ rhs: [Double], tolerance: Double = 1e-9) -> Bool {
    lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { isClose($0, $1, tolerance: tolerance) }
}

/// A Gregorian calendar in UTC, so date tests do not depend on the machine's time zone.
let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// A date in UTC.
func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}
