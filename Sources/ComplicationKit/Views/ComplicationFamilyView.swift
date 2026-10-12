import SwiftUI
#if canImport(WidgetKit) && (os(watchOS) || os(iOS))
import WidgetKit
#endif

/// Shows the right view for the accessory family WidgetKit asks for. Return it from a widget's entry view and
/// list `ComplicationFamily.widgetFamilies` in `supportedFamilies`.
///
/// ```swift
/// struct WaterEntryView: View {
///     let entry: WaterEntry
///
///     var body: some View {
///         ComplicationFamilyView {
///             CircularRingComplication(progress: entry.progress, symbolName: "drop.fill")
///         } corner: {
///             CornerGaugeComplication(value: entry.progress, symbolName: "drop.fill")
///         } rectangular: {
///             RectangularChartComplication(title: "Water", valueText: entry.text, values: entry.history)
///         } inline: {
///             InlineComplication(symbolName: "drop.fill", text: entry.text)
///         }
///     }
/// }
/// ```
///
/// The family comes from, in order: the `family` argument, `.complicationFamily(_:)` (used by the previews),
/// and WidgetKit's `widgetFamily`. Outside a widget, and on the Mac, it falls back to `.circular`.
public struct ComplicationFamilyView<Circular: View, Corner: View, Rectangular: View, Inline: View>: View {
    @Environment(\.complicationFamilyOverride) private var familyOverride
    #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
    @Environment(\.widgetFamily) private var widgetFamily
    #endif

    private let family: ComplicationFamily?
    private let circular: Circular
    private let corner: Corner
    private let rectangular: Rectangular
    private let inline: Inline

    public init(
        family: ComplicationFamily? = nil,
        @ViewBuilder circular: () -> Circular,
        @ViewBuilder corner: () -> Corner,
        @ViewBuilder rectangular: () -> Rectangular,
        @ViewBuilder inline: () -> Inline
    ) {
        self.family = family
        self.circular = circular()
        self.corner = corner()
        self.rectangular = rectangular()
        self.inline = inline()
    }

    /// The family this view shows.
    public var resolvedFamily: ComplicationFamily {
        #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
        let widget = ComplicationFamily(widgetFamily)
        #else
        let widget: ComplicationFamily? = nil
        #endif
        return ComplicationFamily.resolve(explicit: family, override: familyOverride, widget: widget)
    }

    public var body: some View {
        switch resolvedFamily {
        case .circular: circular
        case .corner: corner
        case .rectangular: rectangular
        case .inline: inline
        }
    }
}

extension ComplicationFamilyView where Corner == Circular {
    /// A family view whose corner complication shows the circular content (without a curved label).
    public init(
        family: ComplicationFamily? = nil,
        @ViewBuilder circular: () -> Circular,
        @ViewBuilder rectangular: () -> Rectangular,
        @ViewBuilder inline: () -> Inline
    ) {
        let circularView = circular()
        self.init(family: family, circular: { circularView }, corner: { circularView }, rectangular: rectangular, inline: inline)
    }
}
