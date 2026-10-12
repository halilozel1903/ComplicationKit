import SwiftUI

@main
struct ComplicationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(scene: ScreenshotScene.current)
        }
    }
}
