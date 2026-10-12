import Foundation

/// Short, locale-independent numbers for the few characters a complication has room for.
///
/// ```swift
/// CompactNumber.string(950)          // "950"
/// CompactNumber.string(1_234)        // "1.2K"
/// CompactNumber.string(12_480)       // "12K"
/// CompactNumber.string(2_500_000)    // "2.5M"
/// CompactNumber.string(0.75)         // "0.8"
/// ```
public enum CompactNumber {
    private static let suffixes = ["", "K", "M", "B", "T"]

    /// `value` in at most about four characters plus a suffix: K for thousands, M for millions, B for billions and
    /// T for trillions. Values below 10 (after scaling) keep up to `maximumFractionDigits` decimals, larger ones
    /// are rounded to whole numbers. A value that rounds up to the next unit uses it: 999,600 is "1M", not "1000K".
    /// NaN is "--" and infinity "∞".
    public static func string(_ value: Double, maximumFractionDigits: Int = 1) -> String {
        if value.isNaN { return "--" }
        if value.isInfinite { return value < 0 ? "-∞" : "∞" }
        let digits = max(0, min(maximumFractionDigits, 3))
        let magnitude = abs(value)

        var tier = 0
        while tier < suffixes.count - 1, magnitude >= pow(1000, Double(tier + 1)) {
            tier += 1
        }
        var rounded = 0.0
        var fractionDigits = 0
        while true {
            let scaled = magnitude / pow(1000, Double(tier))
            fractionDigits = scaled < 10 ? digits : 0
            let factor = pow(10, Double(fractionDigits))
            rounded = (scaled * factor).rounded(.toNearestOrAwayFromZero) / factor
            if rounded >= 1000, tier < suffixes.count - 1 {
                tier += 1
                continue
            }
            break
        }
        let sign = value < 0 && rounded != 0 ? "-" : ""
        return sign + decimal(rounded, fractionDigits: fractionDigits) + suffixes[tier]
    }

    /// `value` with at most `fractionDigits` decimals and no trailing zeros, always with a "." separator.
    static func decimal(_ value: Double, fractionDigits: Int) -> String {
        guard fractionDigits > 0 else { return String(format: "%.0f", value) }
        var text = String(format: "%.\(fractionDigits)f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }
}

/// Short durations for countdowns and timers.
///
/// ```swift
/// CompactTime.abbreviated(45)        // "45s"
/// CompactTime.abbreviated(3_900)     // "1h 5m"
/// CompactTime.clock(754)             // "12:34"
/// CompactTime.shortest(5_400)        // "1h"
/// ```
///
/// Negative durations count as zero, NaN is "--", and the seconds are always rounded down, like a countdown.
public enum CompactTime {
    /// Two units at most: "45s", "12m", "1h 5m", "2h", "3d 4h".
    public static func abbreviated(_ seconds: TimeInterval) -> String {
        guard let total = wholeSeconds(seconds) else { return "--" }
        switch total {
        case ..<60:
            return "\(total)s"
        case ..<3_600:
            return "\(total / 60)m"
        case ..<86_400:
            let hours = total / 3_600
            let minutes = total % 3_600 / 60
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        default:
            let days = total / 86_400
            let hours = total % 86_400 / 3_600
            return hours == 0 ? "\(days)d" : "\(days)d \(hours)h"
        }
    }

    /// The largest unit only, for the tightest spots: "45s", "12m", "1h", "3d".
    public static func shortest(_ seconds: TimeInterval) -> String {
        guard let total = wholeSeconds(seconds) else { return "--" }
        switch total {
        case ..<60: return "\(total)s"
        case ..<3_600: return "\(total / 60)m"
        case ..<86_400: return "\(total / 3_600)h"
        default: return "\(total / 86_400)d"
        }
    }

    /// A digital clock: "0:45", "12:34", "1:05:00".
    public static func clock(_ seconds: TimeInterval) -> String {
        guard let total = wholeSeconds(seconds) else { return "--:--" }
        let hours = total / 3_600
        let minutes = total % 3_600 / 60
        let remainder = total % 60
        if hours > 0 {
            return "\(hours):\(twoDigits(minutes)):\(twoDigits(remainder))"
        }
        return "\(minutes):\(twoDigits(remainder))"
    }

    /// Whole seconds, rounded down; `nil` for NaN. Negative values are zero and huge ones are capped at 100 years.
    static func wholeSeconds(_ seconds: TimeInterval) -> Int? {
        guard !seconds.isNaN else { return nil }
        let capped = min(max(seconds, 0), 100 * 365 * 86_400)
        return Int(capped.rounded(.down))
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
