import SwiftUI

/// The gallery: vertically paged screens, each a mock watch face with complications at their real point size.
/// A screenshot launch shows one screen on its own, without the pager.
struct ContentView: View {
    let scene: ScreenshotScene?

    var body: some View {
        Group {
            if let scene {
                page(for: scene)
            } else {
                TabView {
                    FacePage()
                    FacePage(tinted: true)
                    CircularPage()
                    CornerPage()
                    RectangularPage()
                    InlinePage()
                }
                .tabViewStyle(.verticalPage)
            }
        }
        .task {
            guard let scene else { return }
            // Tells scripts/screenshots.sh that the scene is on screen. Nothing in the gallery animates, so the
            // frame is final once it has been drawn.
            let marker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
            try? await Task.sleep(for: .seconds(1))
            try? scene.rawValue.write(to: marker, atomically: true, encoding: .utf8)
        }
    }

    @ViewBuilder
    private func page(for scene: ScreenshotScene) -> some View {
        switch scene {
        case .circular: CircularPage()
        case .corner: CornerPage()
        case .rectangular: RectangularPage()
        case .face: FacePage()
        }
    }
}
