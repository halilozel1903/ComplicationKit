import ComplicationKit
import SwiftUI

/// The tint of the tinted watch face in the gallery.
let galleryFaceTint = Color.orange

extension ComplicationRenderingMode {
    /// The caption above a row of complications.
    var galleryCaption: String {
        switch self {
        case .fullColor: "FULL COLOR"
        case .accented: "TINTED"
        case .vibrant: "VIBRANT"
        }
    }

    /// The face tint to preview with this mode.
    var galleryTint: Color? {
        self == .fullColor ? nil : galleryFaceTint
    }
}

/// A full-screen mock watch face with a title next to the system clock. Complications inside are drawn at the real
/// point size of the watch the app runs on: 46mm and 49mm watches use the 45mm metrics.
struct GalleryScreen<Content: View>: View {
    let title: String?
    @ViewBuilder let content: (ComplicationMetrics) -> Content

    var body: some View {
        GeometryReader { proxy in
            let metrics = ComplicationMetrics.forScreen(width: proxy.size.width)
            MockWatchFace {
                VStack(spacing: 0) {
                    if let title {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.hydrate)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, proxy.size.width * 0.1)
                            .padding(.top, proxy.size.height * 0.04)
                    }
                    content(metrics)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

/// A small caption over a row of complications.
struct GalleryCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.55))
            .lineLimit(1)
    }
}

// MARK: - Circular

/// The three circular templates, in full color and on a tinted face.
struct CircularPage: View {
    var body: some View {
        GalleryScreen(title: "Circular") { metrics in
            VStack(spacing: 10) {
                CircularRow(mode: .fullColor, metrics: metrics)
                CircularRow(mode: .accented, metrics: metrics)
            }
        }
    }
}

private struct CircularRow: View {
    let mode: ComplicationRenderingMode
    let metrics: ComplicationMetrics

    var body: some View {
        let day = HydrateDay.preview
        VStack(spacing: 5) {
            GalleryCaption(text: mode.galleryCaption)
            HStack(spacing: 10) {
                ComplicationPreview(.circular, metrics: metrics, renderingMode: mode, tint: mode.galleryTint) {
                    CircularGaugeComplication(
                        value: day.consumed,
                        in: 0...day.goal,
                        valueText: day.consumedText,
                        symbolName: "drop.fill",
                        colors: [.hydrateDeep, .hydrate, .mint]
                    )
                }
                ComplicationPreview(.circular, metrics: metrics, renderingMode: mode, tint: mode.galleryTint) {
                    HydrateProgressComplication(day: day)
                }
                ComplicationPreview(.circular, metrics: metrics, renderingMode: mode, tint: mode.galleryTint) {
                    HydrateReminderComplication(entry: HydrateSchedule.previewEntry)
                }
            }
        }
    }
}

// MARK: - Corner

/// Corner complications on a face: full color at the bottom, tinted at the top left. The gallery draws their
/// curved labels itself, the way watchOS draws `widgetLabel` along the bezel.
struct CornerPage: View {
    var body: some View {
        GeometryReader { proxy in
            let layout = WatchFaceLayout(size: proxy.size)
            let metrics = layout.metrics
            let day = HydrateDay.preview
            MockWatchFace {
                ZStack {
                    ComplicationPreview(.corner, metrics: metrics, renderingMode: .accented, tint: galleryFaceTint) {
                        CornerGaugeComplication(
                            value: day.consumed,
                            in: 0...day.goal,
                            symbolName: "drop.fill",
                            leadingText: "0",
                            trailingText: day.goalText + "L",
                            colors: [.hydrateDeep, .hydrate]
                        )
                    }
                    .position(x: layout.leadingCornerCenter.x, y: proxy.size.height - layout.leadingCornerCenter.y)

                    VStack(spacing: 4) {
                        Text("10:09")
                            .font(.system(size: layout.timeSize, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        GalleryCaption(text: "CORNER")
                        GalleryCaption(text: "TINTED ABOVE")
                        GalleryCaption(text: "FULL COLOR BELOW")
                    }
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.5)

                    ComplicationPreview(.corner, metrics: metrics, renderingMode: .fullColor) {
                        HydrateProgressComplication(day: day)
                    }
                    .position(x: layout.leadingCornerCenter.x, y: layout.leadingCornerCenter.y)

                    ComplicationPreview(.corner, metrics: metrics, renderingMode: .fullColor) {
                        HydrateReminderComplication(entry: HydrateSchedule.previewEntry)
                    }
                    .position(x: layout.trailingCornerCenter.x, y: layout.trailingCornerCenter.y)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Rectangular

/// The chart template in full color and the text template on a tinted face.
struct RectangularPage: View {
    var body: some View {
        GalleryScreen(title: nil) { metrics in
            VStack(alignment: .leading, spacing: 4) {
                GalleryCaption(text: "RECTANGULAR · " + ComplicationRenderingMode.fullColor.galleryCaption)
                    .padding(.leading, 6)
                ComplicationPreview(.rectangular, metrics: metrics, renderingMode: .fullColor) {
                    HydrateProgressComplication(day: .preview)
                }
                GalleryCaption(text: ComplicationRenderingMode.accented.galleryCaption)
                    .padding(.leading, 6)
                    .padding(.top, 6)
                ComplicationPreview(.rectangular, metrics: metrics, renderingMode: .accented, tint: galleryFaceTint) {
                    HydrateReminderComplication(entry: HydrateSchedule.previewEntry)
                }
            }
            .padding(.top, 10)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Inline

/// Inline complications, which the face draws in its own font above the time.
struct InlinePage: View {
    var body: some View {
        GalleryScreen(title: "Inline") { metrics in
            VStack(alignment: .leading, spacing: 6) {
                ForEach([ComplicationRenderingMode.fullColor, .accented], id: \.self) { mode in
                    GalleryCaption(text: mode.galleryCaption)
                    ComplicationPreview(.inline, metrics: metrics, renderingMode: mode, tint: mode.galleryTint) {
                        HydrateProgressComplication(day: .preview)
                    }
                    ComplicationPreview(.inline, metrics: metrics, renderingMode: mode, tint: mode.galleryTint) {
                        HydrateReminderComplication(entry: HydrateSchedule.previewEntry)
                    }
                }
            }
            .padding(.top, 12)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Watch face

/// A whole mock watch face: the reminder inline at the top, the time, the hourly chart, the progress ring and two
/// corners at the bottom.
struct FacePage: View {
    var tinted = false

    var body: some View {
        WatchFacePreview(time: "10:09") { slot in
            switch slot {
            case .inline, .bottomTrailingCorner:
                HydrateReminderComplication(entry: HydrateSchedule.previewEntry)
            case .rectangular, .circular, .bottomLeadingCorner:
                HydrateProgressComplication(day: .preview)
            }
        }
        .complicationRenderingMode(tinted ? .accented : nil, tint: tinted ? galleryFaceTint : nil)
        .ignoresSafeArea()
    }
}
