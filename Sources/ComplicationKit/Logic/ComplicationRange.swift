import Foundation

/// The bounds of a gauge or progress value, with safe clamping and mapping to a fraction.
///
/// Bounds are sorted, and infinite or NaN bounds are replaced (the lower one by 0, the upper one by 1), so a
/// range is always usable: `fraction(of:)` is always in `0...1` and never NaN.
///
/// ```swift
/// let range = ComplicationRange(40...200)
/// range.clamp(260)          // 200
/// range.fraction(of: 120)   // 0.5
/// ```
public struct ComplicationRange: Hashable, Sendable {
    /// The smallest value.
    public let lowerBound: Double
    /// The largest value.
    public let upperBound: Double

    /// A range from `lower` to `upper`. The bounds are swapped when `lower` is greater than `upper`.
    public init(_ lower: Double, _ upper: Double) {
        let lower = lower.isFinite ? lower : 0
        let upper = upper.isFinite ? upper : 1
        self.lowerBound = min(lower, upper)
        self.upperBound = max(lower, upper)
    }

    /// A range with the bounds of `range`.
    public init(_ range: ClosedRange<Double>) {
        self.init(range.lowerBound, range.upperBound)
    }

    /// `0...1`, the range of a progress fraction.
    public static let unit = ComplicationRange(0, 1)

    /// The distance between the bounds, never negative.
    public var span: Double { upperBound - lowerBound }

    /// The range as a `ClosedRange`, for `Gauge` and `ProgressView`.
    public var closedRange: ClosedRange<Double> { lowerBound...upperBound }

    /// `value` limited to the bounds. NaN becomes the lower bound.
    public func clamp(_ value: Double) -> Double {
        guard !value.isNaN else { return lowerBound }
        return min(max(value, lowerBound), upperBound)
    }

    /// Where `value` sits between the bounds, from 0 at the lower bound to 1 at the upper bound.
    /// Values outside the range are clamped; NaN is 0. In an empty range (equal bounds), values at or above the
    /// bound are 1 and values below it are 0.
    public func fraction(of value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        guard span > 0 else { return value >= upperBound ? 1 : 0 }
        let fraction = (value - lowerBound) / span
        return min(max(fraction, 0), 1)
    }

    /// The value at `fraction` of the way from the lower to the upper bound. The fraction is clamped to `0...1`.
    public func value(atFraction fraction: Double) -> Double {
        let fraction = fraction.isNaN ? 0 : min(max(fraction, 0), 1)
        return lowerBound + span * fraction
    }

    /// `count` evenly spaced values from the lower to the upper bound, both included.
    public func ticks(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [lowerBound] }
        return (0..<count).map { index in
            index == count - 1 ? upperBound : lowerBound + span * Double(index) / Double(count - 1)
        }
    }
}

/// Small helpers for the values a complication shows.
public enum ComplicationValue {
    /// `value` limited to `range`. NaN becomes the lower bound.
    public static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        ComplicationRange(range).clamp(value)
    }

    /// Progress towards `goal` as a fraction in `0...1`: `progress(1.2, goal: 2)` is 0.6.
    /// A goal of zero or less counts as reached as soon as `value` is positive.
    public static func progress(_ value: Double, goal: Double) -> Double {
        guard !value.isNaN, !goal.isNaN else { return 0 }
        guard goal > 0 else { return value > 0 ? 1 : 0 }
        return min(max(value / goal, 0), 1)
    }
}
