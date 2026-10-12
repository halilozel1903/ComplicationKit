import Foundation

/// Scenes used by CI to capture the README screenshots.
/// Launch with `-screenshot <scene>`; normal launches are unaffected.
enum ScreenshotScene: String {
    /// Gauge, progress ring and stack circular complications, in full color and on a tinted face.
    case circular
    /// Corner complications with their curved gauge and label, full color at the bottom and tinted at the top.
    case corner
    /// The hourly chart in full color and the reminder text with its progress bar on a tinted face.
    case rectangular
    /// A whole mock watch face with one complication of each family.
    case face

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScene(rawValue: arguments[index + 1])
    }
}
