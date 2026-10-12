import SwiftUI

/// A black watch screen for previews. It draws the curved labels of the corner complications inside it, which a
/// real watch face does with `widgetLabel`.
///
/// ```swift
/// MockWatchFace {
///     ComplicationPreview(.corner) { MyCornerComplication() }
///         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
/// }
/// ```
public struct MockWatchFace<Content: View>: View {
    private let background: Color
    private let content: Content

    public init(background: Color = .black, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    public var body: some View {
        ZStack {
            background
            RadialGradient(
                colors: [Color.white.opacity(0.07), Color.white.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 220
            )
            content
        }
        .overlayPreferenceValue(CornerLabelPreferenceKey.self) { items in
            CornerLabelsOverlay(items: items)
        }
    }
}

/// Shows a complication at the real size of its family, the way the gallery and the watch face previews draw it.
///
/// ```swift
/// ComplicationPreview(.circular, metrics: .mm45, renderingMode: .accented, tint: .orange) {
///     CircularRingComplication(progress: 0.6, symbolName: "drop.fill")
/// }
/// ```
public struct ComplicationPreview<Content: View>: View {
    private let family: ComplicationFamily
    private let metrics: ComplicationMetrics
    private let renderingMode: ComplicationRenderingMode?
    private let tint: Color?
    private let size: CGSize?
    private let content: Content

    /// - Parameters:
    ///   - family: The family to draw. `ComplicationFamilyView`s inside show this family.
    ///   - metrics: The watch size, which sets the frame.
    ///   - size: A frame that replaces the one from `metrics`, for example a narrower inline slot.
    ///   - renderingMode: The rendering mode to simulate. `nil` keeps the one from the environment.
    ///   - tint: The face tint for `.accented`.
    public init(
        _ family: ComplicationFamily,
        metrics: ComplicationMetrics = .mm45,
        size: CGSize? = nil,
        renderingMode: ComplicationRenderingMode? = nil,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.family = family
        self.metrics = metrics
        self.size = size
        self.renderingMode = renderingMode
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        let frame = size ?? metrics.size(for: family)
        let mode = renderingMode
        let previewTint = self.tint
        return content
            .frame(width: frame.width, height: frame.height, alignment: family == .inline ? .leading : .center)
            .complicationFamily(family)
            .complicationPreview()
            .transformEnvironment(\.complicationRenderingModeOverride) { value in
                if let mode { value = mode }
            }
            .transformEnvironment(\.complicationPreviewTint) { value in
                if let previewTint { value = previewTint }
            }
    }
}

/// A slot of `WatchFacePreview`.
public enum WatchFaceSlot: String, CaseIterable, Hashable, Sendable {
    /// The inline complication at the top.
    case inline
    /// The rectangular complication in the middle.
    case rectangular
    /// The circular complication at the bottom.
    case circular
    /// The corner complication at the bottom left.
    case bottomLeadingCorner
    /// The corner complication at the bottom right.
    case bottomTrailingCorner

    /// The family the slot shows.
    public var family: ComplicationFamily {
        switch self {
        case .inline: .inline
        case .rectangular: .rectangular
        case .circular: .circular
        case .bottomLeadingCorner, .bottomTrailingCorner: .corner
        }
    }
}

/// A mock watch face with one complication of each family at its real size: inline at the top, the time, a
/// rectangular complication, and a circular one between two corners at the bottom.
///
/// Fill the slots one by one:
///
/// ```swift
/// WatchFacePreview(time: "10:09") { slot in
///     switch slot {
///     case .inline: InlineComplication(symbolName: "sun.max.fill", text: "SUNNY 21°")
///     case .rectangular: MyCalendarComplication()
///     case .circular: MyRingComplication()
///     case .bottomLeadingCorner: MyStepsComplication()
///     case .bottomTrailingCorner: MyBatteryComplication()
///     }
/// }
/// ```
///
/// or show the same `ComplicationFamilyView` everywhere with `WatchFacePreview { MyComplication() }`.
/// Apply `.complicationRenderingMode(.accented, tint: .orange)` to see the face tinted.
public struct WatchFacePreview<Content: View>: View {
    private let time: String
    private let timeColor: Color
    private let content: (WatchFaceSlot) -> Content

    public init(time: String = "10:09", timeColor: Color = .white, @ViewBuilder content: @escaping (WatchFaceSlot) -> Content) {
        self.time = time
        self.timeColor = timeColor
        self.content = content
    }

    public var body: some View {
        MockWatchFace {
            GeometryReader { proxy in
                let size = proxy.size
                let layout = WatchFaceLayout(size: size)
                let metrics = layout.metrics
                ZStack(alignment: .topLeading) {
                    slot(.inline, metrics: metrics, size: CGSize(width: layout.inlineWidth, height: metrics.inline.height))
                        .position(x: layout.inlineCenter.x, y: layout.inlineCenter.y)
                    ComplicationStyleReader { style in
                        Text(time)
                            .font(.system(size: layout.timeSize, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(style.color(timeColor, role: .primary))
                    }
                    .position(x: layout.timeCenter.x, y: layout.timeCenter.y)
                    slot(.rectangular, metrics: metrics)
                        .position(x: layout.rectangularCenter.x, y: layout.rectangularCenter.y)
                    slot(.circular, metrics: metrics)
                        .position(x: layout.circularCenter.x, y: layout.circularCenter.y)
                    slot(.bottomLeadingCorner, metrics: metrics)
                        .position(x: layout.leadingCornerCenter.x, y: layout.leadingCornerCenter.y)
                    slot(.bottomTrailingCorner, metrics: metrics)
                        .position(x: layout.trailingCornerCenter.x, y: layout.trailingCornerCenter.y)
                }
                .frame(width: size.width, height: size.height)
            }
        }
    }

    private func slot(_ slot: WatchFaceSlot, metrics: ComplicationMetrics, size: CGSize? = nil) -> some View {
        ComplicationPreview(slot.family, metrics: metrics, size: size) {
            content(slot)
        }
    }
}

extension WatchFacePreview {
    /// A face that shows `complication`, usually a `ComplicationFamilyView`, in every slot.
    public init(
        time: String = "10:09",
        timeColor: Color = .white,
        @ViewBuilder complication: @escaping () -> Content
    ) {
        self.init(time: time, timeColor: timeColor) { _ in complication() }
    }
}

/// Where `WatchFacePreview` puts each complication on a screen of `size`.
public struct WatchFaceLayout: Equatable, Sendable {
    /// The screen size.
    public let size: CGSize
    /// The complication sizes for this screen.
    public let metrics: ComplicationMetrics

    public init(size: CGSize) {
        self.size = size
        self.metrics = ComplicationMetrics.forScreen(width: size.width)
    }

    /// Room left of the system clock, which watchOS draws at the top right of every app.
    public var inlineWidth: CGFloat { min(metrics.inline.width, size.width * 0.56) }

    public var inlineCenter: CGPoint {
        CGPoint(x: size.width * 0.15 + inlineWidth / 2, y: size.height * 0.04 + metrics.inline.height / 2)
    }

    /// The font size of the time.
    public var timeSize: CGFloat { (size.height * 0.17).rounded() }

    /// The center of the time: low enough that its digits stay clear of the system clock at the top right, which
    /// watchOS keeps drawing over every app, and above the rectangular complication.
    public var timeCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.225) }

    public var rectangularCenter: CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.34 + metrics.rectangular.height / 2)
    }

    public var circularCenter: CGPoint {
        let top = size.height * 0.34 + metrics.rectangular.height + size.height * 0.025
        return CGPoint(x: size.width / 2, y: top + metrics.circular.height / 2)
    }

    /// The inset of the corner complications from the screen edges.
    public var cornerInset: CGFloat { (size.width * 0.04).rounded() }

    public var leadingCornerCenter: CGPoint {
        CGPoint(x: cornerInset + metrics.corner.width / 2, y: size.height - cornerInset - metrics.corner.height / 2)
    }

    public var trailingCornerCenter: CGPoint {
        CGPoint(x: size.width - cornerInset - metrics.corner.width / 2, y: size.height - cornerInset - metrics.corner.height / 2)
    }
}

/// Every family of a complication, in full color and on a tinted face, for Xcode previews.
///
/// ```swift
/// #Preview {
///     ComplicationGallery {
///         WaterComplication(entry: .preview)
///     }
/// }
/// ```
public struct ComplicationGallery<Content: View>: View {
    private let screenSize: CGSize
    private let tint: Color
    private let content: () -> Content

    /// - Parameters:
    ///   - screenSize: The watch screen; 208 x 248 points is a 46mm Apple Watch.
    ///   - tint: The tint of the tinted face.
    ///   - content: The complication, usually a `ComplicationFamilyView`.
    public init(
        screenSize: CGSize = CGSize(width: 208, height: 248),
        tint: Color = .orange,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.screenSize = screenSize
        self.tint = tint
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                face(title: "Full color", mode: .fullColor)
                face(title: "Tinted", mode: .accented)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private func face(title: String, mode: ComplicationRenderingMode) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            WatchFacePreview(complication: content)
                .complicationRenderingMode(mode, tint: mode == .fullColor ? nil : tint)
                .frame(width: screenSize.width, height: screenSize.height)
                .clipShape(RoundedRectangle(cornerRadius: screenSize.width * 0.2, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: screenSize.width * 0.2, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }
}
