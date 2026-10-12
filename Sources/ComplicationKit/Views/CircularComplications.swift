import SwiftUI
#if canImport(WidgetKit) && (os(watchOS) || os(iOS))
import WidgetKit
#endif

/// The faint disc behind circular and corner complications: `AccessoryWidgetBackground` inside a widget, a
/// translucent circle in previews and on the Mac.
public struct ComplicationBackground: View {
    @Environment(\.isComplicationPreview) private var isPreview

    public init() {}

    public var body: some View {
        #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
        if isPreview {
            Circle().fill(Color.white.opacity(0.16))
        } else {
            AccessoryWidgetBackground()
        }
        #else
        Circle().fill(Color.white.opacity(0.16))
        #endif
    }
}

/// An open gauge for `.accessoryCircular`: a 270° arc with a gradient and a marker at the value, the value in
/// the middle and a symbol or short label in the gap at the bottom.
///
/// ```swift
/// CircularGaugeComplication(value: 72, in: 0...100, symbolName: "battery.75percent", colors: [.red, .yellow, .green])
/// ```
public struct CircularGaugeComplication: View {
    private let value: Double
    private let range: ComplicationRange
    private let valueText: String
    private let label: String?
    private let symbolName: String?
    private let colors: [Color]
    private let showsBackground: Bool

    /// - Parameters:
    ///   - value: The current value. Values outside `range` sit at its ends.
    ///   - range: The bounds of the gauge.
    ///   - valueText: The text in the middle. Defaults to the value as a compact number ("72", "1.2K").
    ///   - label: A short label in the gap at the bottom, such as "BPM". Ignored when there is a symbol.
    ///   - symbolName: An SF Symbol in the gap at the bottom.
    ///   - colors: The gradient along the arc, from the lower to the upper bound.
    ///   - showsBackground: Draws the faint disc behind the gauge.
    public init(
        value: Double,
        in range: ClosedRange<Double> = 0...1,
        valueText: String? = nil,
        label: String? = nil,
        symbolName: String? = nil,
        colors: [Color] = [.green, .yellow, .orange, .red],
        showsBackground: Bool = true
    ) {
        self.value = value
        self.range = ComplicationRange(range)
        self.valueText = valueText ?? CompactNumber.string(value)
        self.label = label
        self.symbolName = symbolName
        self.colors = colors
        self.showsBackground = showsBackground
    }

    public var body: some View {
        ComplicationStyleReader { style in
            GeometryReader { proxy in
                let side = max(min(proxy.size.width, proxy.size.height), 1)
                let lineWidth = max(side * 0.09, 2)
                let fraction = range.fraction(of: value)
                let painted = style.colors(colors)
                ZStack {
                    if showsBackground {
                        ComplicationBackground()
                    }
                    OpenArc(fraction: 1, sweep: 270)
                        .stroke(
                            AngularGradient(colors: painted, center: .center, startAngle: .zero, endAngle: .degrees(270)),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))
                        .padding(side * 0.1)
                        .complicationAccentable()
                    GaugeMarker(fraction: fraction, sweep: 270, startAngle: 135, diameter: lineWidth * 1.5)
                        .padding(side * 0.1)
                    Text(valueText)
                        .font(.system(size: side * 0.3, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(style.color(.white, role: .primary))
                        .padding(.horizontal, side * 0.22)
                    bottom(side: side, style: style)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, side * 0.04)
                }
                .frame(width: side, height: side)
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Gauge")
        .accessibilityValue(valueText)
    }

    @ViewBuilder
    private func bottom(side: CGFloat, style: ComplicationStyle) -> some View {
        if let symbolName {
            Image(systemName: symbolName)
                .font(.system(size: side * 0.2, weight: .bold))
                .foregroundStyle(style.color(colors.last ?? .white))
                .complicationAccentable()
        } else if let label {
            Text(label)
                .font(.system(size: side * 0.15, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(style.color(.white, role: .secondary))
                .frame(maxWidth: side * 0.4)
        }
    }
}

/// A closed progress ring for `.accessoryCircular`, with a symbol over the value in the middle.
///
/// ```swift
/// CircularRingComplication(progress: 0.6, valueText: "1.2", symbolName: "drop.fill", tint: .cyan)
/// ```
public struct CircularRingComplication: View {
    private let progress: Double
    private let valueText: String?
    private let symbolName: String?
    private let tint: Color
    private let showsBackground: Bool

    /// - Parameters:
    ///   - progress: The filled share of the ring, clamped to `0...1`.
    ///   - valueText: The text in the middle. Defaults to the progress in percent.
    ///   - symbolName: An SF Symbol above the text.
    ///   - tint: The ring color.
    ///   - showsBackground: Draws the faint disc behind the ring.
    public init(progress: Double, valueText: String? = nil, symbolName: String? = nil, tint: Color = .cyan, showsBackground: Bool = true) {
        self.progress = ComplicationRange.unit.clamp(progress)
        self.valueText = valueText
        self.symbolName = symbolName
        self.tint = tint
        self.showsBackground = showsBackground
    }

    public var body: some View {
        let text = valueText ?? "\(Int((progress * 100).rounded()))%"
        return ComplicationStyleReader { style in
            GeometryReader { proxy in
                let side = max(min(proxy.size.width, proxy.size.height), 1)
                let lineWidth = max(side * 0.1, 2)
                ZStack {
                    if showsBackground {
                        ComplicationBackground()
                    }
                    Group {
                        Circle()
                            .stroke(style.color(tint).opacity(0.3), lineWidth: lineWidth)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(style.color(tint), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .padding(lineWidth / 2 + side * 0.04)
                    .complicationAccentable()
                    VStack(spacing: 0) {
                        if let symbolName {
                            Image(systemName: symbolName)
                                .font(.system(size: side * 0.2, weight: .bold))
                                .foregroundStyle(style.color(tint))
                                .complicationAccentable()
                        }
                        Text(text)
                            .font(.system(size: side * (symbolName == nil ? 0.3 : 0.24), weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(style.color(.white, role: .primary))
                    }
                    .padding(.horizontal, side * 0.2)
                }
                .frame(width: side, height: side)
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(text)
    }
}

/// A stack for `.accessoryCircular`: a small symbol or caption on top, a large value and a unit below it.
///
/// ```swift
/// CircularStackComplication(top: .symbol("thermometer.medium"), value: "21°", bottom: "H 24")
/// ```
public struct CircularStackComplication: View {
    /// What sits above the value.
    public enum Top: Hashable, Sendable {
        case symbol(String)
        case text(String)
    }

    private let top: Top?
    private let value: String
    private let bottom: String?
    private let tint: Color
    private let showsBackground: Bool

    public init(top: Top? = nil, value: String, bottom: String? = nil, tint: Color = .orange, showsBackground: Bool = true) {
        self.top = top
        self.value = value
        self.bottom = bottom
        self.tint = tint
        self.showsBackground = showsBackground
    }

    public var body: some View {
        ComplicationStyleReader { style in
            GeometryReader { proxy in
                let side = max(min(proxy.size.width, proxy.size.height), 1)
                ZStack {
                    if showsBackground {
                        ComplicationBackground()
                    }
                    VStack(spacing: -side * 0.02) {
                        switch top {
                        case .symbol(let name):
                            Image(systemName: name)
                                .font(.system(size: side * 0.22, weight: .semibold))
                                .foregroundStyle(style.color(tint))
                                .complicationAccentable()
                        case .text(let text):
                            Text(text)
                                .font(.system(size: side * 0.17, weight: .bold, design: .rounded))
                                .foregroundStyle(style.color(tint))
                                .complicationAccentable()
                        case nil:
                            EmptyView()
                        }
                        Text(value)
                            .font(.system(size: side * 0.34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(style.color(.white, role: .primary))
                        if let bottom {
                            Text(bottom)
                                .font(.system(size: side * 0.16, weight: .semibold, design: .rounded))
                                .foregroundStyle(style.color(.white, role: .secondary))
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, side * 0.14)
                }
                .frame(width: side, height: side)
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shapes

/// An arc that starts at 3 o'clock and runs clockwise for `sweep * fraction` degrees.
struct OpenArc: Shape {
    var fraction: Double
    var sweep: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let end = sweep * min(max(fraction, 0), 1)
        var path = Path()
        let steps = max(Int(end / 4), 1)
        for step in 0...steps {
            let angle = end * Double(step) / Double(steps) * .pi / 180
            let point = CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

/// A white dot with a dark outline at `fraction` along an arc that starts at `startAngle` and spans `sweep`.
struct GaugeMarker: View {
    var fraction: Double
    var sweep: Double
    var startAngle: Double
    var diameter: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            let angle = (startAngle + sweep * min(max(fraction, 0), 1)) * .pi / 180
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black, lineWidth: max(diameter * 0.22, 1)))
                .frame(width: diameter, height: diameter)
                .position(
                    x: proxy.size.width / 2 + radius * CGFloat(cos(angle)),
                    y: proxy.size.height / 2 + radius * CGFloat(sin(angle))
                )
        }
    }
}
