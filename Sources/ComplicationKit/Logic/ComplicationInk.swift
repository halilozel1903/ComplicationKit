import Foundation

/// How the watch face renders complications. Mirrors WidgetKit's `WidgetRenderingMode`, which only exists on
/// watchOS and iOS, so the same logic also runs (and is tested) on the Mac.
public enum ComplicationRenderingMode: String, CaseIterable, Hashable, Sendable {
    /// Full color faces: every part keeps its own color.
    case fullColor
    /// Tinted faces: the system paints the accented parts (marked `widgetAccentable`) in the face's tint color and
    /// everything else in a desaturated white.
    case accented
    /// The iPhone Lock Screen: content becomes a monochrome, translucent material. White is fully opaque.
    case vibrant
}

/// The job a part of a complication does, which decides how it is painted in each rendering mode.
public enum ComplicationInkRole: String, CaseIterable, Hashable, Sendable {
    /// Gauges, rings, symbols and other colored parts. They follow the face tint on tinted faces.
    case accent
    /// The main text and numbers.
    case primary
    /// Captions, units and tracks.
    case secondary
}

/// How a part is painted.
public enum ComplicationInk: Hashable, Sendable {
    /// The part's own color.
    case original
    /// The preview tint, which stands in for the face's tint color in the gallery.
    case tint
    /// White at an opacity: the system turns it into the tint (accented parts) or the material (vibrant mode).
    case white(opacity: Double)

    /// The ink for a part with `role` in `mode`. `hasPreviewTint` is `true` in the gallery, where no watch face
    /// tints the accented parts, so they are painted with the preview tint directly.
    public static func resolve(role: ComplicationInkRole, mode: ComplicationRenderingMode, hasPreviewTint: Bool) -> ComplicationInk {
        switch mode {
        case .fullColor:
            return .original
        case .accented:
            switch role {
            case .accent: return hasPreviewTint ? .tint : .white(opacity: 1)
            case .primary: return .white(opacity: 1)
            case .secondary: return .white(opacity: 0.6)
            }
        case .vibrant:
            switch role {
            case .accent, .primary: return .white(opacity: 1)
            case .secondary: return .white(opacity: 0.55)
            }
        }
    }
}

/// Maps chart values to bar heights.
public enum ComplicationChart {
    /// Bar heights as fractions of the chart height, relative to the largest value (or to `maximum` when given).
    /// Negative, NaN and infinite values are 0. Values above zero get at least `minimumFraction`, so small values stay
    /// visible next to zero ones.
    public static func barFractions(_ values: [Double], maximum: Double? = nil, minimumFraction: Double = 0.06) -> [Double] {
        let finite = values.map { $0.isFinite ? max($0, 0) : 0 }
        let top = maximum.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? finite.max() ?? 0
        guard top > 0 else { return finite.map { _ in 0 } }
        let minimum = min(max(minimumFraction, 0), 1)
        return finite.map { value in
            guard value > 0 else { return 0 }
            return min(max(value / top, minimum), 1)
        }
    }
}
