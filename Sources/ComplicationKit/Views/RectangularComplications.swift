import SwiftUI

/// A header and up to two lines of text, with an optional progress bar, for `.accessoryRectangular`.
///
/// ```swift
/// RectangularTextComplication(
///     title: "Standup",
///     symbolName: "calendar",
///     headline: "10:30 – 10:45",
///     detail: "Room 4 · Ada, Grace",
///     tint: .red
/// )
/// ```
public struct RectangularTextComplication: View {
    private let title: String
    private let symbolName: String?
    private let headline: String
    private let detail: String?
    private let progress: Double?
    private let tint: Color

    /// - Parameters:
    ///   - title: The header, drawn in the tint color.
    ///   - symbolName: An SF Symbol before the header.
    ///   - headline: The main line, large.
    ///   - detail: A second, smaller line.
    ///   - progress: A progress bar under the text, from 0 to 1.
    ///   - tint: The color of the header, the symbol and the progress bar.
    public init(
        title: String,
        symbolName: String? = nil,
        headline: String,
        detail: String? = nil,
        progress: Double? = nil,
        tint: Color = .orange
    ) {
        self.title = title
        self.symbolName = symbolName
        self.headline = headline
        self.detail = detail
        self.progress = progress.map { ComplicationRange.unit.clamp($0) }
        self.tint = tint
    }

    public var body: some View {
        ComplicationStyleReader { style in
            GeometryReader { proxy in
                let height = max(proxy.size.height, 1)
                VStack(alignment: .leading, spacing: height * 0.02) {
                    RectangularHeader(title: title, symbolName: symbolName, tint: tint, size: height * 0.2, style: style)
                    Text(headline)
                        .font(.system(size: height * 0.27, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(style.color(.white, role: .primary))
                    if let detail {
                        Text(detail)
                            .font(.system(size: height * 0.2, weight: .medium, design: .rounded))
                            .foregroundStyle(style.color(.white, role: .secondary))
                    }
                    if let progress {
                        ProgressBar(progress: progress, colors: [tint], style: style)
                            .frame(height: max(height * 0.07, 3))
                            .padding(.top, height * 0.03)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A header with the current value and a small bar chart, for `.accessoryRectangular`.
///
/// ```swift
/// RectangularChartComplication(
///     title: "Water",
///     symbolName: "drop.fill",
///     valueText: "1.2 L",
///     values: [0.2, 0.35, 0, 0.25, 0.3, 0.1],
///     tint: .cyan
/// )
/// ```
public struct RectangularChartComplication: View {
    private let title: String
    private let symbolName: String?
    private let valueText: String
    private let values: [Double]
    private let maximum: Double?
    private let highlightedIndex: Int?
    private let leadingAxisText: String?
    private let trailingAxisText: String?
    private let tint: Color

    /// - Parameters:
    ///   - title: The header, drawn in the tint color.
    ///   - symbolName: An SF Symbol before the header.
    ///   - valueText: The current value, at the end of the header.
    ///   - values: One bar per value. Negative values draw no bar.
    ///   - maximum: The value of a full-height bar. Defaults to the largest value.
    ///   - highlightedIndex: The bar drawn at full strength, such as the current hour. Defaults to the last one.
    ///   - leadingAxisText: A caption under the first bar, such as "6AM".
    ///   - trailingAxisText: A caption under the last bar, such as "NOW".
    ///   - tint: The color of the header and the bars.
    public init(
        title: String,
        symbolName: String? = nil,
        valueText: String,
        values: [Double],
        maximum: Double? = nil,
        highlightedIndex: Int? = nil,
        leadingAxisText: String? = nil,
        trailingAxisText: String? = nil,
        tint: Color = .cyan
    ) {
        self.title = title
        self.symbolName = symbolName
        self.valueText = valueText
        self.values = values
        self.maximum = maximum
        self.highlightedIndex = highlightedIndex
        self.leadingAxisText = leadingAxisText
        self.trailingAxisText = trailingAxisText
        self.tint = tint
    }

    public var body: some View {
        let fractions = ComplicationChart.barFractions(values, maximum: maximum)
        let highlighted = highlightedIndex ?? (values.count - 1)
        return ComplicationStyleReader { style in
            GeometryReader { proxy in
                let height = max(proxy.size.height, 1)
                let hasAxis = leadingAxisText != nil || trailingAxisText != nil
                VStack(alignment: .leading, spacing: height * 0.04) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        RectangularHeader(title: title, symbolName: symbolName, tint: tint, size: height * 0.2, style: style)
                        Spacer(minLength: 2)
                        Text(valueText)
                            .font(.system(size: height * 0.24, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(style.color(.white, role: .primary))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                    HStack(alignment: .bottom, spacing: max(height * 0.03, 1.5)) {
                        ForEach(fractions.indices, id: \.self) { index in
                            BarShape(fraction: fractions[index])
                                .fill(style.color(tint).opacity(index == highlighted ? 1 : 0.5))
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .complicationAccentable()

                    if hasAxis {
                        HStack {
                            Text(leadingAxisText ?? "")
                            Spacer(minLength: 0)
                            Text(trailingAxisText ?? "")
                        }
                        .font(.system(size: height * 0.13, weight: .semibold, design: .rounded))
                        .foregroundStyle(style.color(.white, role: .secondary))
                        .lineLimit(1)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText)
    }
}

/// The symbol and uppercased title at the top of a rectangular complication.
struct RectangularHeader: View {
    let title: String
    let symbolName: String?
    let tint: Color
    let size: CGFloat
    let style: ComplicationStyle

    var body: some View {
        HStack(spacing: size * 0.3) {
            if let symbolName {
                Image(systemName: symbolName)
            }
            Text(title.uppercased())
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .foregroundStyle(style.color(tint))
        .lineLimit(1)
        .complicationAccentable()
    }
}

/// A rounded bar as tall as `fraction` of the available height. Zero draws a thin baseline.
struct BarShape: Shape {
    var fraction: Double

    func path(in rect: CGRect) -> Path {
        let height = max(rect.height * CGFloat(min(max(fraction, 0), 1)), min(rect.height, 1.5))
        let bar = CGRect(x: rect.minX, y: rect.maxY - height, width: rect.width, height: height)
        let radius = min(rect.width / 2, height / 2, 3)
        return Path(roundedRect: bar, cornerRadius: radius)
    }
}

/// A horizontal progress bar with a faint track.
struct ProgressBar: View {
    let progress: Double
    let colors: [Color]
    let style: ComplicationStyle

    var body: some View {
        GeometryReader { proxy in
            let painted = style.colors(colors)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(painted[0].opacity(0.3))
                Capsule()
                    .fill(LinearGradient(colors: painted, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(proxy.size.width * CGFloat(progress), proxy.size.height))
                    .opacity(progress > 0 ? 1 : 0)
            }
        }
        .complicationAccentable()
    }
}
