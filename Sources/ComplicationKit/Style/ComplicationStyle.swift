import SwiftUI
#if canImport(WidgetKit) && (os(watchOS) || os(iOS))
import WidgetKit
#endif

/// The resolved look of a complication: the rendering mode of the face and, in the gallery, the tint that stands in
/// for the face's tint color. Read it with `ComplicationStyleReader`.
public struct ComplicationStyle: Equatable, Sendable {
    /// How the face renders complications.
    public var renderingMode: ComplicationRenderingMode
    /// The color accented parts are painted with in the gallery. `nil` inside a real widget, where the system
    /// applies the face's tint itself.
    public var previewTint: Color?

    public init(renderingMode: ComplicationRenderingMode = .fullColor, previewTint: Color? = nil) {
        self.renderingMode = renderingMode
        self.previewTint = previewTint
    }

    /// Full color, no tint.
    public static let fullColor = ComplicationStyle()

    /// `true` on tinted faces and the Lock Screen.
    public var isTinted: Bool { renderingMode != .fullColor }

    /// How a part with `role` is painted.
    public func ink(for role: ComplicationInkRole) -> ComplicationInk {
        ComplicationInk.resolve(role: role, mode: renderingMode, hasPreviewTint: previewTint != nil)
    }

    /// The color to paint a part whose full color is `color`.
    public func color(_ color: Color, role: ComplicationInkRole = .accent) -> Color {
        switch ink(for: role) {
        case .original: color
        case .tint: previewTint ?? color
        case .white(let opacity): Color.white.opacity(opacity)
        }
    }

    /// The colors to paint a gradient whose full colors are `colors`.
    public func colors(_ colors: [Color], role: ComplicationInkRole = .accent) -> [Color] {
        let painted = colors.map { color($0, role: role) }
        return painted.isEmpty ? [color(.white, role: role)] : painted
    }
}

// MARK: - Environment

private struct RenderingModeOverrideKey: EnvironmentKey {
    static let defaultValue: ComplicationRenderingMode? = nil
}

private struct PreviewTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct IsPreviewKey: EnvironmentKey {
    static let defaultValue = false
}

private struct FamilyOverrideKey: EnvironmentKey {
    static let defaultValue: ComplicationFamily? = nil
}

extension EnvironmentValues {
    /// A rendering mode that replaces the one WidgetKit reports. Set by the preview views.
    public var complicationRenderingModeOverride: ComplicationRenderingMode? {
        get { self[RenderingModeOverrideKey.self] }
        set { self[RenderingModeOverrideKey.self] = newValue }
    }

    /// The color that stands in for the face's tint color in previews.
    public var complicationPreviewTint: Color? {
        get { self[PreviewTintKey.self] }
        set { self[PreviewTintKey.self] = newValue }
    }

    /// `true` when complications are drawn by the gallery rather than by a watch face. Corner complications then
    /// draw their curved labels themselves, because `widgetLabel` only works inside a widget.
    public var isComplicationPreview: Bool {
        get { self[IsPreviewKey.self] }
        set { self[IsPreviewKey.self] = newValue }
    }

    /// A family that replaces the one WidgetKit reports, so `ComplicationFamilyView` can be previewed in any family.
    public var complicationFamilyOverride: ComplicationFamily? {
        get { self[FamilyOverrideKey.self] }
        set { self[FamilyOverrideKey.self] = newValue }
    }
}

extension View {
    /// Draws the complications inside in `mode`. In the gallery, pass a `tint` to paint the accented parts the way
    /// a tinted watch face would. `nil` goes back to the mode WidgetKit reports.
    public func complicationRenderingMode(_ mode: ComplicationRenderingMode?, tint: Color? = nil) -> some View {
        environment(\.complicationRenderingModeOverride, mode)
            .environment(\.complicationPreviewTint, tint)
    }

    /// Marks the complications inside as drawn by a preview rather than a watch face.
    public func complicationPreview(_ isPreview: Bool = true) -> some View {
        environment(\.isComplicationPreview, isPreview)
    }

    /// Makes `ComplicationFamilyView`s inside show `family`, whatever WidgetKit reports.
    public func complicationFamily(_ family: ComplicationFamily?) -> some View {
        environment(\.complicationFamilyOverride, family)
    }

    /// Marks the view as part of the accent group, which tinted watch faces paint in their tint color.
    /// `widgetAccentable` on watchOS and iOS; does nothing on the Mac.
    @ViewBuilder
    public func complicationAccentable(_ accentable: Bool = true) -> some View {
        #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
        self.widgetAccentable(accentable)
        #else
        self
        #endif
    }
}

// MARK: - Reader

/// Reads the complication style from the environment: the preview override if there is one, otherwise the
/// rendering mode WidgetKit reports.
///
/// ```swift
/// ComplicationStyleReader { style in
///     Image(systemName: "drop.fill")
///         .foregroundStyle(style.color(.cyan))
///         .complicationAccentable()
/// }
/// ```
public struct ComplicationStyleReader<Content: View>: View {
    @Environment(\.complicationRenderingModeOverride) private var modeOverride
    @Environment(\.complicationPreviewTint) private var previewTint
    #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    #endif

    private let content: (ComplicationStyle) -> Content

    public init(@ViewBuilder content: @escaping (ComplicationStyle) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ComplicationStyle(renderingMode: modeOverride ?? systemMode, previewTint: previewTint))
    }

    private var systemMode: ComplicationRenderingMode {
        #if canImport(WidgetKit) && (os(watchOS) || os(iOS))
        if widgetRenderingMode == .accented { return .accented }
        if widgetRenderingMode == .vibrant { return .vibrant }
        return .fullColor
        #else
        return .fullColor
        #endif
    }
}
