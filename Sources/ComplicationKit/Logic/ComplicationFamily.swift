import CoreGraphics
import Foundation

/// The four WidgetKit accessory families a watch face can show.
public enum ComplicationFamily: String, CaseIterable, Hashable, Sendable {
    /// `.accessoryCircular`: a small circle, on most faces and in the Smart Stack.
    case circular
    /// `.accessoryCorner`: a small circle in a corner of the face, with a curved label or gauge along the bezel.
    /// Apple Watch only.
    case corner
    /// `.accessoryRectangular`: a wide box with up to three lines of text, a gauge or a chart. Also the Smart
    /// Stack widget.
    case rectangular
    /// `.accessoryInline`: one line of text with an optional symbol, above the time.
    case inline

    /// A readable name, such as "Circular".
    public var displayName: String {
        switch self {
        case .circular: "Circular"
        case .corner: "Corner"
        case .rectangular: "Rectangular"
        case .inline: "Inline"
        }
    }

    /// The family to draw: an explicit choice first, then a preview override, then the family WidgetKit reports
    /// (if it is an accessory family), and finally `.circular`.
    public static func resolve(
        explicit: ComplicationFamily?,
        override: ComplicationFamily?,
        widget: ComplicationFamily?
    ) -> ComplicationFamily {
        explicit ?? override ?? widget ?? .circular
    }
}

/// Apple Watch case sizes, grouped the way Apple's Human Interface Guidelines list complication sizes.
public enum WatchCaseSize: String, CaseIterable, Hashable, Sendable {
    /// 40mm and the older 42mm watches.
    case mm40 = "40mm"
    /// 41mm watches.
    case mm41 = "41mm"
    /// 44mm watches, and the 42mm Series 10 and later.
    case mm44 = "44mm"
    /// 45mm, 46mm and 49mm (Ultra) watches.
    case mm45 = "45mm"
}

/// The point sizes of each complication family on one Apple Watch size.
///
/// Circular, corner and rectangular sizes come from the "Complications" page of Apple's Human Interface
/// Guidelines (the image sizes for each layout). The inline family has no documented size: it is one line of text,
/// so its height here is an approximation of a line at the face's complication font size.
public struct ComplicationMetrics: Equatable, Sendable {
    /// The watch size these metrics describe.
    public let caseSize: WatchCaseSize
    /// The size of an `.accessoryCircular` complication.
    public let circular: CGSize
    /// The size of the circular content of an `.accessoryCorner` complication (without its curved label).
    public let corner: CGSize
    /// The size of an `.accessoryRectangular` complication.
    public let rectangular: CGSize
    /// The approximate size of an `.accessoryInline` complication.
    public let inline: CGSize
    /// The default text size of circular complications.
    public let circularTextSize: CGFloat
    /// The default text size of corner complications and their curved labels.
    public let cornerTextSize: CGFloat
    /// The default text size of rectangular complications.
    public let rectangularTextSize: CGFloat

    /// The size of `family`.
    public func size(for family: ComplicationFamily) -> CGSize {
        switch family {
        case .circular: circular
        case .corner: corner
        case .rectangular: rectangular
        case .inline: inline
        }
    }

    /// 40mm and older 42mm watches.
    public static let mm40 = ComplicationMetrics(
        caseSize: .mm40,
        circular: CGSize(width: 42, height: 42),
        corner: CGSize(width: 32, height: 32),
        rectangular: CGSize(width: 162, height: 69),
        inline: CGSize(width: 162, height: 18),
        circularTextSize: 12,
        cornerTextSize: 10,
        rectangularTextSize: 16.5
    )

    /// 41mm watches.
    public static let mm41 = ComplicationMetrics(
        caseSize: .mm41,
        circular: CGSize(width: 44.5, height: 44.5),
        corner: CGSize(width: 34, height: 34),
        rectangular: CGSize(width: 171.5, height: 73),
        inline: CGSize(width: 171.5, height: 19),
        circularTextSize: 12.5,
        cornerTextSize: 10.5,
        rectangularTextSize: 17.5
    )

    /// 44mm watches.
    public static let mm44 = ComplicationMetrics(
        caseSize: .mm44,
        circular: CGSize(width: 47, height: 47),
        corner: CGSize(width: 36, height: 36),
        rectangular: CGSize(width: 184, height: 78),
        inline: CGSize(width: 184, height: 20),
        circularTextSize: 13,
        cornerTextSize: 11,
        rectangularTextSize: 18
    )

    /// 45mm, 46mm and 49mm watches.
    public static let mm45 = ComplicationMetrics(
        caseSize: .mm45,
        circular: CGSize(width: 50, height: 50),
        corner: CGSize(width: 38, height: 38),
        rectangular: CGSize(width: 193, height: 82),
        inline: CGSize(width: 193, height: 21),
        circularTextSize: 14.5,
        cornerTextSize: 12,
        rectangularTextSize: 19.5
    )

    /// The metrics of `caseSize`.
    public static func of(_ caseSize: WatchCaseSize) -> ComplicationMetrics {
        switch caseSize {
        case .mm40: .mm40
        case .mm41: .mm41
        case .mm44: .mm44
        case .mm45: .mm45
        }
    }

    /// The metrics for a watch whose screen is `width` points wide: 162 (40mm), 176 (41mm), 184 (44mm),
    /// 187 (42mm Series 10), 198 (45mm), 205 (49mm) or 208 (46mm).
    public static func forScreen(width: CGFloat) -> ComplicationMetrics {
        switch width {
        case ..<170: .mm40
        case ..<180: .mm41
        case ..<196: .mm44
        default: .mm45
        }
    }
}
