import SwiftUI
#if canImport(WidgetKit) && (os(watchOS) || os(iOS))
import WidgetKit
#endif

/// A corner complication with a curved gauge along the bezel, for `.accessoryCorner`.
///
/// Inside a widget the gauge is a `Gauge` in `widgetLabel`, which watchOS curves along the corner of the face.
/// In previews (`WatchFacePreview`, `ComplicationGallery`) the view draws the same curved gauge itself, because
/// `widgetLabel` only works inside a widget.
///
/// ```swift
/// CornerGaugeComplication(value: 0.62, symbolName: "drop.fill", leadingText: "0", trailingText: "2L", colors: [.blue, .cyan])
/// ```
public struct CornerGaugeComplication: View {
    @Environment(\.isComplicationPreview) private var isPreview

    private let value: Double
    private let range: ComplicationRange
    private let symbolName: String?
    private let valueText: String?
    private let leadingText: String?
    private let trailingText: String?
    private let colors: [Color]

    /// - Parameters:
    ///   - value: The current value. Values outside `range` sit at its ends.
    ///   - range: The bounds of the gauge.
    ///   - symbolName: An SF Symbol in the corner circle.
    ///   - valueText: A short text in the corner circle when there is no symbol, such as "62%".
    ///   - leadingText: The label at the start of the gauge, usually the lower bound.
    ///   - trailingText: The label at the end of the gauge, usually the upper bound.
    ///   - colors: The gradient along the gauge.
    public init(
        value: Double,
        in range: ClosedRange<Double> = 0...1,
        symbolName: String? = nil,
        valueText: String? = nil,
        leadingText: String? = nil,
        trailingText: String? = nil,
        colors: [Color] = [.green, .yellow, .red]
    ) {
        self.value = value
        self.range = ComplicationRange(range)
        self.symbolName = symbolName
        self.valueText = valueText
        self.leadingText = leadingText
        self.trailingText = trailingText
        self.colors = colors
    }

    public var body: some View {
        ComplicationStyleReader { style in
            let content = CornerCenter(symbolName: symbolName, text: valueText ?? CompactNumber.string(value), tint: colors.last ?? .white, style: style)
            let label = CornerLabel(
                kind: .gauge(fraction: range.fraction(of: value), leading: leadingText, trailing: trailingText),
                colors: style.colors(colors),
                textColor: style.color(.white, role: .primary)
            )
            if isPreview {
                content.anchorPreference(key: CornerLabelPreferenceKey.self, value: .bounds) { anchor in
                    [CornerLabelItem(bounds: anchor, label: label)]
                }
            } else {
                widgetLabeled(content, style: style)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(symbolName ?? "Gauge")
        .accessibilityValue(valueText ?? CompactNumber.string(value))
    }

    @ViewBuilder
    private func widgetLabeled(_ content: some View, style: ComplicationStyle) -> some View {
        #if os(watchOS)
        content.widgetLabel {
            Gauge(value: range.clamp(value), in: range.closedRange) {
                Text(symbolName ?? "")
            } currentValueLabel: {
                Text(valueText ?? CompactNumber.string(value))
            } minimumValueLabel: {
                Text(leadingText ?? "")
            } maximumValueLabel: {
                Text(trailingText ?? "")
            }
            .tint(Gradient(colors: style.colors(colors)))
        }
        #else
        content
        #endif
    }
}

/// A corner complication with curved text along the bezel, for `.accessoryCorner`.
///
/// ```swift
/// CornerTextComplication(symbolName: "figure.walk", label: "6,480 STEPS", tint: .green)
/// ```
public struct CornerTextComplication: View {
    @Environment(\.isComplicationPreview) private var isPreview

    private let symbolName: String?
    private let valueText: String?
    private let label: String
    private let tint: Color

    /// - Parameters:
    ///   - symbolName: An SF Symbol in the corner circle.
    ///   - valueText: A short text in the corner circle when there is no symbol.
    ///   - label: The curved text. Keep it short: a corner fits about 12 characters.
    ///   - tint: The color of the symbol and the label.
    public init(symbolName: String? = nil, valueText: String? = nil, label: String, tint: Color = .green) {
        self.symbolName = symbolName
        self.valueText = valueText
        self.label = label
        self.tint = tint
    }

    public var body: some View {
        ComplicationStyleReader { style in
            let content = CornerCenter(symbolName: symbolName, text: valueText ?? "", tint: tint, style: style)
            let curved = CornerLabel(kind: .text(label), colors: [style.color(tint)], textColor: style.color(tint))
            if isPreview {
                content.anchorPreference(key: CornerLabelPreferenceKey.self, value: .bounds) { anchor in
                    [CornerLabelItem(bounds: anchor, label: curved)]
                }
            } else {
                widgetLabeled(content, style: style)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func widgetLabeled(_ content: some View, style: ComplicationStyle) -> some View {
        #if os(watchOS)
        content.widgetLabel {
            Text(label)
                .foregroundStyle(style.color(tint))
        }
        #else
        content
        #endif
    }
}

/// The circle of a corner complication: a symbol or a short text on the faint background.
struct CornerCenter: View {
    let symbolName: String?
    let text: String
    let tint: Color
    let style: ComplicationStyle

    var body: some View {
        GeometryReader { proxy in
            let side = max(min(proxy.size.width, proxy.size.height), 1)
            ZStack {
                ComplicationBackground()
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: side * 0.46, weight: .semibold))
                        .foregroundStyle(style.color(tint))
                        .complicationAccentable()
                } else {
                    Text(text)
                        .font(.system(size: side * 0.36, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(style.color(.white, role: .primary))
                        .padding(.horizontal, side * 0.1)
                }
            }
            .frame(width: side, height: side)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Curved labels in previews

/// What a corner complication draws along the bezel.
struct CornerLabel: Sendable {
    enum Kind: Sendable {
        case text(String)
        case gauge(fraction: Double, leading: String?, trailing: String?)
    }

    var kind: Kind
    var colors: [Color]
    var textColor: Color
}

/// A corner label and where its corner circle is, collected by `MockWatchFace`.
struct CornerLabelItem {
    var bounds: Anchor<CGRect>
    var label: CornerLabel
}

struct CornerLabelPreferenceKey: PreferenceKey {
    static var defaultValue: [CornerLabelItem] { [] }

    static func reduce(value: inout [CornerLabelItem], nextValue: () -> [CornerLabelItem]) {
        value.append(contentsOf: nextValue())
    }
}

/// A corner label with its corner circle in the face's coordinates.
struct PlacedCornerLabel: Sendable {
    var rect: CGRect
    var label: CornerLabel
}

/// Draws the curved labels of the corner complications on a face.
struct CornerLabelsOverlay: View {
    let items: [CornerLabelItem]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let placed = items.map { PlacedCornerLabel(rect: proxy[$0.bounds], label: $0.label) }
            Canvas { context, _ in
                for item in placed {
                    CornerLabelRenderer.draw(item, faceSize: size, in: &context)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum CornerLabelRenderer {
    static func draw(_ item: PlacedCornerLabel, faceSize: CGSize, in context: inout GraphicsContext) {
        let fontSize = max(item.rect.width * 0.32, 7)
        let gap = fontSize * 0.35
        switch item.label.kind {
        case .text(let string):
            let glyphs = resolve(string, size: fontSize, color: item.label.textColor, in: context)
            let length = glyphs.reduce(0) { $0 + $1.width }
            let arc = CornerLabelLayout.arc(faceSize: faceSize, content: item.rect, length: length)
            drawGlyphs(glyphs, along: arc, from: 0, in: &context)

        case .gauge(let fraction, let leading, let trailing):
            let leadingGlyphs = resolve(leading ?? "", size: fontSize * 0.85, color: item.label.textColor, in: context)
            let trailingGlyphs = resolve(trailing ?? "", size: fontSize * 0.85, color: item.label.textColor, in: context)
            let leadingLength = leadingGlyphs.reduce(0) { $0 + $1.width }
            let trailingLength = trailingGlyphs.reduce(0) { $0 + $1.width }
            let gaugeLength = item.rect.width * 1.3
            let gaugeStart = leadingLength + (leadingGlyphs.isEmpty ? 0 : gap)
            let total = gaugeStart + gaugeLength + (trailingGlyphs.isEmpty ? 0 : gap) + trailingLength
            let arc = CornerLabelLayout.arc(faceSize: faceSize, content: item.rect, length: total)

            drawGlyphs(leadingGlyphs, along: arc, from: 0, in: &context)
            drawGauge(
                along: arc,
                from: gaugeStart,
                length: gaugeLength,
                fraction: fraction,
                colors: item.label.colors,
                lineWidth: max(fontSize * 0.42, 2),
                in: &context
            )
            drawGlyphs(trailingGlyphs, along: arc, from: gaugeStart + gaugeLength + gap, in: &context)
        }
    }

    struct Glyph {
        var text: GraphicsContext.ResolvedText
        var width: CGFloat
    }

    private static func resolve(_ string: String, size: CGFloat, color: Color, in context: GraphicsContext) -> [Glyph] {
        let font = Font.system(size: size, weight: .semibold, design: .rounded)
        return string.map { character in
            let text = context.resolve(Text(String(character)).font(font).foregroundStyle(color))
            let measured = text.measure(in: CGSize(width: 400, height: 400)).width
            return Glyph(text: text, width: character == " " ? max(measured, size * 0.3) : measured)
        }
    }

    private static func drawGlyphs(_ glyphs: [Glyph], along arc: CornerLabelArc, from offset: CGFloat, in context: inout GraphicsContext) {
        var distance = offset
        for glyph in glyphs {
            let angle = arc.angle(atDistance: distance + glyph.width / 2)
            let point = arc.point(atAngle: angle)
            var glyphContext = context
            glyphContext.translateBy(x: point.x, y: point.y)
            glyphContext.rotate(by: .degrees(arc.glyphRotation(atAngle: angle)))
            glyphContext.draw(glyph.text, at: .zero, anchor: .center)
            distance += glyph.width
        }
    }

    private static func drawGauge(
        along arc: CornerLabelArc,
        from offset: CGFloat,
        length: CGFloat,
        fraction: Double,
        colors: [Color],
        lineWidth: CGFloat,
        in context: inout GraphicsContext
    ) {
        func path(to end: CGFloat) -> Path {
            var path = Path()
            let steps = 24
            for step in 0...steps {
                let point = arc.point(atAngle: arc.angle(atDistance: offset + end * CGFloat(step) / CGFloat(steps)))
                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            return path
        }
        let start = arc.point(atAngle: arc.angle(atDistance: offset))
        let end = arc.point(atAngle: arc.angle(atDistance: offset + length))
        let gradient = Gradient(colors: colors.isEmpty ? [.white] : colors)
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)

        var track = context
        track.opacity = 0.35
        track.stroke(path(to: length), with: .linearGradient(gradient, startPoint: start, endPoint: end), style: style)

        let filled = length * CGFloat(min(max(fraction, 0), 1))
        if filled > 0 {
            context.stroke(path(to: filled), with: .linearGradient(gradient, startPoint: start, endPoint: end), style: style)
        }

        let marker = arc.point(atAngle: arc.angle(atDistance: offset + filled))
        let diameter = lineWidth * 1.5
        let dot = Path(ellipseIn: CGRect(x: marker.x - diameter / 2, y: marker.y - diameter / 2, width: diameter, height: diameter))
        context.fill(dot, with: .color(.white))
        context.stroke(dot, with: .color(.black), lineWidth: max(diameter * 0.2, 1))
    }
}
